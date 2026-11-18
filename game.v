// game.v

// connects all components of the game together
// TEMPORARY CONTROLS:
//    KEY[0] = reset
//    lanes (left to right) = SW[0], SW[1], SW[2], SW[3]
//    SCORE = HEX1, HEX0

// TEMPORARY PLACEHOLDERS:
//    enable (FSM), frame_tick, spawn (note chart ROM), press (keyboard)

module game (CLOCK_50, SW, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, x, y, color, write);

  parameter nX = 9;  // 320 -> 9 bits
  parameter nY = 8;  // 240 -> 8 bits
  parameter FRAME_CLOCKS = 833333;  // clock cycles per frame: 50 MHz / 60 Hz
  parameter FRAMES_PER_STEP = 6;  // frames between each note movement

  input CLOCK_50;
  input [9:0] SW;
  input [3:0] KEY;
  output [9:0] LEDR;
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  output [nX-1:0] x;
  output [nY-1:0] y;
  output [8:0] color;
  output write;

  wire resetn;
  assign resetn = KEY[0];

  // TEMPORARY PLAY STATE: REPLACE W/ FSM
  wire enable;
  assign enable = 1'b1;

  // TEMPORARY FRAME TICK
  reg [19:0] frame_count;
  wire frame_tick;
  assign frame_tick = (frame_count == FRAME_CLOCKS - 1);
  always @(posedge CLOCK_50) begin
    if (!resetn || frame_tick)
      frame_count <= 20'd0;
    else
      frame_count <= frame_count + 1'b1;
  end

  // scroll timer
  wire scroll_tick;
  scroll_timer ST (
    .clock(CLOCK_50), 
    .resetn(resetn), 
    .frame_tick(frame_tick), 
    .scroll_tick(scroll_tick)
  );
  
  defparam ST.FRAMES_PER_STEP = FRAMES_PER_STEP;

  // TEMPORARY NOTE CHART: REPLACE W/ NOTE CHART ROM
  // step counts 0 to 7 and a note is spawned in a different lane every 2 steps
  reg [2:0] step;
  always @(posedge CLOCK_50) begin
    if (!resetn)
      step <= 3'd0;
    else if (scroll_tick)
      step <= step + 1'b1;
  end

  wire [3:0] spawn;
  assign spawn = {step == 3'd6, step == 3'd4, step == 3'd2, step == 3'd0};

  // the 4 lanes
  wire [59:0] notes;
  wire [3:0] hit, miss;

  lane L0 (
    .clock(CLOCK_50), 
    .resetn(resetn), 
    .enable(enable), 
    .scroll_tick(scroll_tick),
    .spawn(spawn[0]), 
    .press(SW[0]), 
    .notes(notes[14:0]),  
    .hit(hit[0]), 
    .miss(miss[0])
  );
  lane L1 (
    .clock(CLOCK_50), 
    .resetn(resetn), 
    .enable(enable), 
    .scroll_tick(scroll_tick),        
    .spawn(spawn[1]), 
    .press(SW[1]), 
    .notes(notes[29:15]), 
    .hit(hit[1]), 
    .miss(miss[1]));
  lane L2 (
    .clock(CLOCK_50), 
    .resetn(resetn), 
    .enable(enable), 
    .scroll_tick(scroll_tick),
    .spawn(spawn[2]), 
    .press(SW[2]), 
    .notes(notes[44:30]), 
    .hit(hit[2]), 
    .miss(miss[2])
  );
  lane L3 (
    .clock(CLOCK_50), 
    .resetn(resetn), 
    .enable(enable), 
    .scroll_tick(scroll_tick),
    .spawn(spawn[3]), 
    .press(SW[3]), 
    .notes(notes[59:45]),
    .hit(hit[3]), 
    .miss(miss[3])
  );

  // score on the hex displays
  wire any_hit;
  assign any_hit = hit[0] | hit[1] | hit[2] | hit[3];

  wire [3:0] ones, tens;
  score_counter SC (.clock(CLOCK_50), .resetn(resetn), .hit(any_hit), .ones(ones), .tens(tens));

  hex7seg H0 (.digit(ones), .hex(HEX0));
  hex7seg H1 (.digit(tens), .hex(HEX1));
  assign HEX2 = 7'b1111111;
  assign HEX3 = 7'b1111111;
  assign HEX4 = 7'b1111111;
  assign HEX5 = 7'b1111111;

  // the fretboard
  wire done;
  fretboard FB (.clock(CLOCK_50), .resetn(resetn), .notes(notes),
                .x(x), .y(y), .color(color), .write(write), .done(done));
  defparam FB.nX = nX;
  defparam FB.nY = nY;

  assign LEDR[9] = done;       // on once the first full screen has been drawn
  assign LEDR[8:0] = 9'b0;

endmodule