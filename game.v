
//game.v
// Connects all components 
// Controls:
//   KEY[0] = reset (active low)
//   D F J K = lanes 0..3
//   Enter = start game, Space = return to start screen after game over
//
// Debug LEDs:
//   LEDR[0] = START state, LEDR[1] = PLAY state, LEDR[2] = GAMEOVER state
//   LEDR[3] = lane_held[0], LEDR[4] = lane_held[1]
//   LEDR[5] = lane_held[2], LEDR[6] = lane_held[3]
//   LEDR[9] = first full screen drawn
//
// Required files: lane.v, fretboard.v, FSM.v, keyboardparser.v, scroll_timer.v, scroll_display.v

module game (CLOCK_50, SW, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
             PS2_CLK, PS2_DAT, x, y, color, write);

  parameter nX = 9;                 // 320 -> 9 bits
  parameter nY = 8;                 // 240 -> 8 bits
  parameter FRAMES_PER_STEP = 6;    // frames between each note movement
  parameter SONG_FRAMES = 3600;      // 10 s for testing, use 3600 for 60 s

  input CLOCK_50;
  input [9:0] SW;
  input [3:0] KEY;
  input PS2_CLK, PS2_DAT;
  output [9:0] LEDR;
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  output [nX-1:0] x;
  output [nY-1:0] y;
  output [8:0] color;
  output write;

  wire resetn;
  assign resetn = KEY[0];

  // ------------------------------------------------------------------
  // Keyboard
  // ------------------------------------------------------------------
  wire [3:0] lane_press, lane_held;
  wire start_key, advance_key;

  keyboard_parser KP (
    .clk(CLOCK_50),
    .resetn(resetn),
    .ps2_clk(PS2_CLK),
    .ps2Data(PS2_DAT),
    .lane_press(lane_press),
    .lane_held(lane_held),
    .start_key(start_key),
    .advance_key(advance_key)
  );

  // ------------------------------------------------------------------
  // Frame tick (60 Hz), song timer and game FSM
  // ------------------------------------------------------------------
  wire tick;
  frame_tick FT (.clk(CLOCK_50), .resetn(resetn), .tick(tick));

  wire in_start, in_play, in_gameover, timer_run, timer_clear, song_done;
  wire [15:0] song_frame;

  song_timer #(.SONG_FRAMES(SONG_FRAMES)) STM (
    .clk(CLOCK_50),
    .resetn(resetn),
    .tick(tick),
    .run(timer_run),
    .clear(timer_clear),
    .frame_count(song_frame),
    .song_done(song_done)
  );

  game_fsm GFSM (
    .clk(CLOCK_50),
    .resetn(resetn),
    .start_key(start_key),
    .advance_key(advance_key),
    .song_done(song_done),
    .in_start(in_start),
    .in_play(in_play),
    .in_gameover(in_gameover),
    .timer_run(timer_run),
    .timer_clear(timer_clear)
  );

  wire enable;
  assign enable = in_play;

  // ------------------------------------------------------------------
  // Scroll timer (restarts every time a game begins)
  // ------------------------------------------------------------------
  wire scroll_tick;
  scroll_timer #(.FRAMES_PER_STEP(FRAMES_PER_STEP)) ST (
    .clock(CLOCK_50),
    .resetn(resetn & in_play),
    .frame_tick(tick),
    .scroll_tick(scroll_tick)
  );

  // ------------------------------------------------------------------
  // TEMPORARY NOTE CHART: REPLACE W/ NOTE CHART ROM
  // step counts 0 to 7, a note spawns in a different lane every 2 steps
  // ------------------------------------------------------------------
  reg [2:0] step;
  always @(posedge CLOCK_50) begin
    if (!resetn || !in_play)
      step <= 3'd0;
    else if (scroll_tick)
      step <= step + 1'b1;
  end

  wire [3:0] spawn;
  assign spawn = {step == 3'd6, step == 3'd4, step == 3'd2, step == 3'd0} &
                 {4{scroll_tick}};

  // ------------------------------------------------------------------
  // The 4 lanes
  // ------------------------------------------------------------------
  wire [59:0] notes;
  wire [3:0] hit, miss;

  lane L0 (.clock(CLOCK_50), .resetn(resetn), .enable(enable),
           .scroll_tick(scroll_tick), .spawn(spawn[0]), .press(lane_held[0]),
           .notes(notes[14:0]), .hit(hit[0]), .miss(miss[0]));

  lane L1 (.clock(CLOCK_50), .resetn(resetn), .enable(enable),
           .scroll_tick(scroll_tick), .spawn(spawn[1]), .press(lane_held[1]),
           .notes(notes[29:15]), .hit(hit[1]), .miss(miss[1]));

  lane L2 (.clock(CLOCK_50), .resetn(resetn), .enable(enable),
           .scroll_tick(scroll_tick), .spawn(spawn[2]), .press(lane_held[2]),
           .notes(notes[44:30]), .hit(hit[2]), .miss(miss[2]));

  lane L3 (.clock(CLOCK_50), .resetn(resetn), .enable(enable),
           .scroll_tick(scroll_tick), .spawn(spawn[3]), .press(lane_held[3]),
           .notes(notes[59:45]), .hit(hit[3]), .miss(miss[3]));

  // ------------------------------------------------------------------
  // Score on the HEX displays (cleared when a new game starts)
  // ------------------------------------------------------------------
  wire any_hit;
  assign any_hit = hit[0] | hit[1] | hit[2] | hit[3];

  wire [3:0] ones, tens;
  score_counter SC (
    .clock(CLOCK_50),
    .resetn(resetn & ~in_start),
    .hit(any_hit),
    .ones(ones),
    .tens(tens)
  );

  hex7seg H0 (.digit(ones), .hex(HEX0));
  hex7seg H1 (.digit(tens), .hex(HEX1));
  assign HEX2 = 7'b1111111;
  assign HEX3 = 7'b1111111;
  assign HEX4 = 7'b1111111;
  assign HEX5 = 7'b1111111;

  // ------------------------------------------------------------------
  // Fretboard (VGA pixel stream)
  // ------------------------------------------------------------------
  wire done;
  fretboard #(.nX(nX), .nY(nY)) FB (
    .clock(CLOCK_50),
    .resetn(resetn),
    .notes(notes),
    .x(x),
    .y(y),
    .color(color),
    .write(write),
    .done(done)
  );

  // ------------------------------------------------------------------
  // Debug LEDs
  // ------------------------------------------------------------------
  assign LEDR[0] = in_start;
  assign LEDR[1] = in_play;
  assign LEDR[2] = in_gameover;
  assign LEDR[6:3] = lane_held;
  assign LEDR[8:7] = 2'b00;
  assign LEDR[9] = done;

endmodule
