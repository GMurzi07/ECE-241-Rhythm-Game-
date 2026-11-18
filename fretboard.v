// fretboard.v

// draws the screen one pixel at a time (320x240)
// keep track of current pixel, determine position and assign colour
// whole screen is redrawn continuously

module fretboard (clock, resetn, notes, x, y, color, write, done);

  parameter nX = 9;  // bits for x: 320 -> 9
  parameter nY = 8;  // bits for y: 240 -> 8

  parameter LANE_W = 28;  // width of one lane
  parameter BW = 112;  // width of the board  (4 lanes x 28)
  parameter B0 = 32;  // left edge of the board
  parameter TARGET_SLOT = 12;  // slot (row) where the target boxes are

  // colours, 9 bits: RRR_GGG_BBB
  parameter BG = 9'b000_000_000;  // black background
  parameter BOARD = 9'b001_001_001;  // gray fretboard
  parameter DIVIDER = 9'b101_101_101;  // gray lane divider
  parameter EDGE = 9'b111_111_111;  // white board border
  parameter LEFT = 9'b110_010_100;  // left
  parameter M_LEFT = 9'b000_100_110;  // middle left
  parameter M_RIGHT = 9'b001_100_100;  // middle right
  parameter RIGHT = 9'b110_100_001;  // right

  parameter W = 320;  // real screen width in pixels
  parameter H = 240;  // real screen height in pixels

  input clock, resetn;

  // 4 lanes x 15 slots
  // lane 1 [14:0], lane 2 [29:15], lane 3 [44:30], lane 4 [59:45]
  input [59:0] notes;
  output reg [nX-1:0] x;
  output reg [nY-1:0] y;
  output [8:0] color;
  output write;
  output reg done;  // high when first full screen is drawn

  // every pixel, left to right, top to bottom, forever
  always @(posedge clock) begin
    if (!resetn) begin
      x <= 0;
      y <= 0;
      done <= 1'b0;
    end
    else begin
      if (x == W - 1) begin
        x <= 0;
        if (y == H - 1) begin
          y <= 0;
          done <= 1'b1;
        end
        else
          y <= y + 1'b1;
      end
      else
        x <= x + 1'b1;
    end
  end

  assign write = resetn;

  // find colour of pixel
  // checks if pixel is on the fretboard
  wire in_board;
  assign in_board = (x >= B0) && (x < B0 + BW);

  // left_dist: how far from the left edge of fretboard
  wire [8:0] left_dist;
  assign left_dist = x - B0;

  // determine which lane 
  wire lane0, lane1, lane2;
  assign lane0 = (left_dist < LANE_W);
  assign lane1 = (left_dist < 2 * LANE_W);
  assign lane2 = (left_dist < 3 * LANE_W);
  wire [1:0] lane;
  assign lane = lane0 ? 2'd0 : (lane1 ? 2'd1 : (lane2 ? 2'd2 : 2'd3));

  // determine where current lane starts relative to fretboard
  wire [8:0] lane_start;
  assign lane_start = lane0 ? 9'd0 : (lane1 ? LANE_W : (lane2 ? 2 * LANE_W : 3 * LANE_W));

  // determine position relative to lane
  wire [8:0] pos_lane;
  assign pos_lane = left_dist - lane_start;

  // determine colour of lane
  wire [8:0] lane_color;
  assign lane_color = (lane == 0) ? LEFT :
                      (lane == 1) ? M_LEFT :
                      (lane == 2) ? M_RIGHT : RIGHT;

  // is there a note at this pixel's row in this pixel's lane?
  wire [14:0] lane_slot;  // 15 slots for this pixel's lane
  assign lane_slot = (lane == 0) ? notes[14:0] :
                     (lane == 1) ? notes[29:15] :
                     (lane == 2) ? notes[44:30] : notes[59:45];

  wire [3:0] slot;  // which 16-pixel row we are in
  wire [3:0] row;  // pixel row inside that slot
  assign slot = y[7:4];
  assign row = y[3:0];

  wire note_here;
  assign note_here = lane_slot[slot];

  // determine the shape
  wire in_note_box, in_target_box, target_edge, note_pixel, edge_pixel, divider_pixel;
  
  // falling notes
  assign in_note_box = (pos_lane >= 4) && 
                       (pos_lane <= LANE_W - 5) && 
                       (row >= 2) && 
                       (row <= 13);

  // target boxes
  assign in_target_box = (slot == TARGET_SLOT) && 
                         (pos_lane >= 2) && 
                         (pos_lane <= LANE_W - 3);

  // border of target box
  assign target_edge = in_target_box && 
                       ((pos_lane <= 3) || 
                       (pos_lane >= LANE_W - 4) || 
                       (row <= 1) || 
                       (row >= 14));

  assign note_pixel = note_here && in_note_box;
  assign edge_pixel = (left_dist <= 1) || (left_dist >= BW - 2);
  assign divider_pixel = (pos_lane <= 1);

  // pick the colour (the first line that is true)
  assign color = !in_board ? BG :
                  edge_pixel ? EDGE :
                  note_pixel ? lane_color :
                  target_edge ? lane_color :
                  divider_pixel ? DIVIDER : BOARD;

endmodule