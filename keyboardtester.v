module keyboardtester (
    input  wire CLOCK_50,
    input  wire [0:0] KEY,
    inout  wire PS2_CLK,
    inout  wire PS2_DAT,
    output wire [9:0] LEDR
);
    wire [3:0] lane_press;
    wire [3:0] lane_held;
    wire  start_key;
    wire  advance_key;

    keyboard_parser #(.NUM_LANES(4)) kp (
        .clk(CLOCK_50), .resetn(KEY[0]),
        .ps2_clk(PS2_CLK), .ps2Data(PS2_DAT),
        .lane_press(lane_press), .lane_held(lane_held),
        .start_key(start_key), .advance_key(advance_key));

    assign LEDR[3:0] = lane_held;
    assign LEDR[4] = start_key;
    assign LEDR[5] = advance_key;
    assign LEDR[9:6] = 4'b0000;
endmodule
