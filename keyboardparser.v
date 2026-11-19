
// ps2_receiver: deserializes the PS/2 clock/data lines into scan codes
// keyboard_parser: decodes scan codes  into per-lane signals

// Key map:
//   Lane 0 = D   Lane 1 = F   Lane 2 = J   Lane 3 = K
//   Start  = Enter  Advance = Space

// Outputs:
//   lane_held[i]: high while the lane key is physically held down
//   lane_press[i]: one-clock pulse when the key is first pressed
//                 
//  start_key / advance_key : level outputs (held). game_fsm does its
//  own rising-edge detect, so these stay as levels.

// PS/2 receiver: 11-bit frame = start, 8 data (LSB first),
// odd parity, stop. Data is sampled on the falling edge of PS2_CLK.

module ps2_receiver #(parameter TIMEOUT_CLKS = 50000)(  //50000 cycles = 1 ms at 50 MHz, used to detect when keyboard stops trasmitting in middle of frame 
    input  wire       clk,
    input  wire       resetn,
    input  wire       ps2_clk,
    input  wire       ps2Data,
    output reg  [7:0] scan_code,
    output reg        scan_valid    // one-clock pulse, scan_code is valid
);
    
    reg [2:0] clk_sync; // 3 stages to allow for reliable edge detection of the PS/2 clock
    reg [1:0] dat_sync; 

    always @(posedge clk) begin
        if (!resetn) begin
            //Ps2 clock idles high --> avoid false falling edge detection on reset
            clk_sync <= 3'b111;
            dat_sync <= 2'b11;
        end else begin
            // Shift in the PS/2 clock and data signals to synchronize them to the system clock
            clk_sync <= {clk_sync[1:0], ps2_clk};
            dat_sync <= {dat_sync[0], ps2Data};
        end
    end
    //detect falling edge of PS/2 clock to sample data
    wire falling = clk_sync[2] & ~clk_sync[1];
    wire dat     = dat_sync[1];

    reg [3:0] bit_cnt; //tracks which part of Ps2 frame is being received 
    reg [7:0] shiftReg;
    reg parity_bit;
    reg [15:0] timeout; //tracks how long the receiver has gone without receiving another falling edge of Ps2 clocl

    always @(posedge clk) begin
        scan_valid <= 1'b0;

        if (!resetn) begin
            bit_cnt    <= 4'd0;
            shiftReg      <= 8'd0;
            parity_bit <= 1'b0;
            timeout    <= 16'd0;
            scan_code  <= 8'd0;
        end else if (falling) begin
            timeout <= 16'd0;
            case (bit_cnt)
            //start bit must be o if one we must stay 
                4'd0: begin 
                    if (!dat) bit_cnt <= 4'd1;
                end

                4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8: begin
                    shiftReg   <= {dat, shiftReg[7:1]};
                    bit_cnt <= bit_cnt + 1'b1;
                end
                4'd9: begin
                    parity_bit <= dat;
                    bit_cnt    <= 4'd10;
                end
                4'd10: begin // stop bit must be 1, parity must be odd
                    if (dat && ((^shiftReg) ^ parity_bit)) begin
                        scan_code  <= shiftReg;
                        scan_valid <= 1'b1;
                    end
                    bit_cnt <= 4'd0;
                end
                default: bit_cnt <= 4'd0;
            endcase
        end else if (bit_cnt != 4'd0) begin
            // Abandon a partial frame if the clock goes idle mid-byte
            if (timeout == TIMEOUT_CLKS) begin
                bit_cnt <= 4'd0;
                timeout <= 16'd0;
            end else begin
                timeout <= timeout + 1'b1;
            end
        end
    end
endmodule


// Keyboard parser
// Scan code set : a key release is sent as F0 followed by the
// key's code.
module keyboard_parser #(parameter NUM_LANES = 4)(   
    input  wire clk,
    input  wire resetn,
    input  wire ps2_clk,
    input  wire ps2Data,

    output reg  [NUM_LANES-1:0] lane_press,
    output reg  [NUM_LANES-1:0] lane_held,
    output reg                  start_key,
    output reg                  advance_key
);
    // Scan codes (set 2). Lane 3 is the top byte, lane 0 the bottom byte.
    localparam [31:0] LANE_KEYS = {8'h42,    // K -> lane 3
                                   8'h3B,    // J -> lane 2
                                   8'h2B,    // F -> lane 1
                                   8'h23};   // D -> lane 0
    localparam [7:0] KEY_ENTER = 8'h5A;
    localparam [7:0] KEY_SPACE = 8'h29;
    localparam [7:0] CODE_BREAK = 8'hF0;

    wire [7:0] scan_code;
    wire       scan_valid;

    ps2_receiver rx (
        .clk(clk), .resetn(resetn),
        .ps2_clk(ps2_clk), .ps2Data(ps2Data),
        .scan_code(scan_code), .scan_valid(scan_valid));

    reg break_next;  // last byte was F0, so the next code is a release
    integer i;

    always @(posedge clk) begin
        lane_press <= {NUM_LANES{1'b0}};   // default: pulses last 1 clock

        if (!resetn) begin
            lane_held   <= {NUM_LANES{1'b0}};
            start_key   <= 1'b0;
            advance_key <= 1'b0;
            break_next  <= 1'b0;
        end else if (scan_valid) begin
            if (scan_code == CODE_BREAK) begin
                break_next <= 1'b1;
            end else begin
                break_next <= 1'b0;

                for (i = 0; i < NUM_LANES; i = i + 1) begin
                    // Check if the scan code matches the lane key
                    if (scan_code == LANE_KEYS[8*i +: 8]) begin
                        if (break_next) begin
                            lane_held[i] <= 1'b0;
                        end else begin
                            if (!lane_held[i])
                                lane_press[i] <= 1'b1;  // new press only
                            lane_held[i] <= 1'b1;
                        end
                    end
                end

                if (scan_code == KEY_ENTER)
                    start_key <= !break_next;
                if (scan_code == KEY_SPACE)
                    advance_key <= !break_next;
            end
        end
    end
endmodule