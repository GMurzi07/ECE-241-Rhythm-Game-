// Rhythm Game - Game FSM, Frame Tick, Song Timer (single player)
//  50 MHz clock and 60 FPS VGA frame rate.
// Needs to update 60 times per second to match VGA refresh rate
// 50_000_000 / 60 = 833333

module frame_tick #(parameter CLKS_PER_FRAME = 833333)(
    input  wire clk,
    input  wire resetn,     // active-low
    output reg  tick
);
    reg [21:0] cnt; // 22 bits to count to 833333

    always @(posedge clk) begin
        if (!resetn) begin
            cnt  <= 22'd0;
            tick <= 1'b0;
        end else if (cnt == CLKS_PER_FRAME - 1) begin
            cnt  <= 22'd0;
            tick <= 1'b1;
        end else begin
            cnt  <= cnt + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule


// Song timer: counts how many frames have passed since the song started.

module song_timer #(parameter SONG_FRAMES = 3600)(  // 3600 frames = 60 s
    input  wire clk,
    input  wire resetn,
    input  wire tick,     // 1 if new frame has passed
    input  wire run,      // high when game is running in PLAY state
    input  wire clear,    // resets the counter
    output reg  [15:0] frame_count, // 60 s x 60 fps = 3600 frames fits in 12 bits
    output wire song_done
);
    assign song_done = (frame_count >= SONG_FRAMES); // checks if song is done

    always @(posedge clk) begin
        if (!resetn || clear)
            frame_count <= 16'd0;
        else if (run && tick && !song_done)
            frame_count <= frame_count + 1'b1;
    end
endmodule



// FMS: START -> PLAY -> GAMEOVER -> START
//   START: title screen, wait for start key
//   PLAY : song running, notes scrolling, scoring active
//   GAMEOVER: song finished, show final score, wait for key to restart

module game_fsm(
    input  wire clk,
    input  wire resetn,
    input  wire start_key,     // from keyboard parser (e.g. Enter)
    input  wire advance_key,   // fard parser (e.g. Space)rom keybo
    input  wire song_done,     // from song_timer

    output wire in_start,
    output wire in_play,
    output wire in_gameover,
    output wire timer_run,
    output wire timer_clear
);
    localparam [1:0] S_START    = 2'd0, // Defining state codes 
                     S_PLAY     = 2'd1,
                     S_GAMEOVER = 2'd2;

    reg [1:0] state, next_state;

    // Rising-edge detect so a held key only triggers one transition
    reg start_q, adv_q; // Startq remembers the previous value of start key, Advq remembers the previous value of advance key
    wire start_pulse = start_key   & ~start_q;
    wire adv_pulse   = advance_key & ~adv_q;

    always @(posedge clk) begin
        if (!resetn) begin
            start_q <= 1'b0;
            adv_q   <= 1'b0;
        end else begin
            start_q <= start_key;
            adv_q   <= advance_key;
        end
    end

    // State register
    always @(posedge clk) begin
        if (!resetn) state <= S_START;
        else state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = state; //if none of conditons are met, stay in the same state
        case (state)
            S_START: if (start_pulse) next_state = S_PLAY;
            S_PLAY: if (song_done)   next_state = S_GAMEOVER;
            S_GAMEOVER: if (adv_pulse) next_state = S_START;
            default:  next_state = S_START;
        endcase
    end

    // Outputs
    assign in_start = (state == S_START);
    assign in_play = (state == S_PLAY);
    assign in_gameover = (state == S_GAMEOVER);
    assign timer_run = in_play;
    assign timer_clear = in_start;
endmodule