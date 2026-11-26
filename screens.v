// screens.v

// picks the final colour of every pixel depending on the game state
//   START    : title + "PRESS ENTER" on black
//   PLAY     : fretboard + score progress bar (top right)
//   GAMEOVER : "GAME OVER", final score, "PRESS SPACE" + progress bar
// score progress bar = score (0..198) as a 100 pixel wide bar, 1 pixel per 2 points
// (99 notes x 2 points for a perfect = 198 = full bar)

module screens (x, y, in_start, in_play, in_gameover, hundreds, tens, ones, board_color, color);

  parameter nX = 9;
  parameter nY = 8;

  // colours, 9 bits: RRR_GGG_BBB
  parameter BG = 9'b000_000_000;
  parameter WHITE = 9'b111_111_111;
  parameter YELLOW = 9'b111_111_000;
  parameter RED = 9'b111_001_001;
  parameter CYAN = 9'b000_111_111;
  parameter BAR_EMPTY = 9'b010_010_010;
  parameter BAR_FILL = 9'b000_111_000;

  // progress bar: 1 px border around a 100 x 8 inner area, top right
  parameter BAR_X = 209;  // left edge of the inner area
  parameter BAR_Y = 9;  // top edge of the inner area
  parameter BAR_W = 100;
  parameter BAR_H = 8;

  // text lines: glyphs are 5x7 drawn at scale 2 (10x14) inside a 16 px wide cell
  parameter L0_Y = 64;
  parameter L1_Y = 112;
  parameter L2_Y = 160;

  input [nX-1:0] x;
  input [nY-1:0] y;
  input in_start, in_play, in_gameover;
  input [3:0] hundreds, tens, ones;
  input [8:0] board_color;
  output [8:0] color;

  // progress bar
  wire [8:0] score_bin;  // BCD -> binary (max 198 in this game)
  assign score_bin = (hundreds * 9'd100) + (tens << 3) + (tens << 1) + ones;

  wire in_inner, in_outer, bar_border, bar_fill;
  assign in_inner = (x >= BAR_X) && (x < BAR_X + BAR_W) &&
                    (y >= BAR_Y) && (y < BAR_Y + BAR_H);
  assign in_outer = (x >= BAR_X - 1) && (x < BAR_X + BAR_W + 1) &&
                    (y >= BAR_Y - 1) && (y < BAR_Y + BAR_H + 1);
  assign bar_border = in_outer && !in_inner;
  assign bar_fill = in_inner && ((x - BAR_X) < score_bin[8:1]);

  wire bar_pixel;
  assign bar_pixel = !in_start && in_outer;

  wire [8:0] bar_color;
  assign bar_color = bar_border ? WHITE :
                     bar_fill ? BAR_FILL : BAR_EMPTY;

  // which text line is this pixel row in?
  wire in_l0, in_l1, in_l2;
  assign in_l0 = (y >= L0_Y) && (y < L0_Y + 14);
  assign in_l1 = (y >= L1_Y) && (y < L1_Y + 14);
  assign in_l2 = (y >= L2_Y) && (y < L2_Y + 14);

  wire [1:0] line;
  assign line = in_l0 ? 2'd0 : (in_l1 ? 2'd1 : 2'd2);

  wire in_line;  // start screen only has lines 0 and 1
  assign in_line = in_start ? (in_l0 | in_l1) :
                   in_gameover ? (in_l0 | in_l1 | in_l2) : 1'b0;

  wire [7:0] line_y;
  assign line_y = in_l0 ? L0_Y : (in_l1 ? L1_Y : L2_Y);

  wire [7:0] dy;
  assign dy = y - line_y;  // 0..13 inside a line
  wire [2:0] glyph_row;
  assign glyph_row = dy[3:1];

  // left edge of the text, chosen so each string is roughly centred
  wire [8:0] x0;
  assign x0 = in_start ? 9'd72 :
              in_l0 ? 9'd88 :   // GAME OVER (9 chars)
              in_l1 ? 9'd88 :   // SCORE xxx (9 chars)
                      9'd72;    // PRESS SPACE (11 chars)

  wire [8:0] dx;
  assign dx = x - x0;
  wire [4:0] idx;  // which character in the line
  assign idx = dx[8:4];
  wire [3:0] sub;  // pixel inside the 16 px cell
  assign sub = dx[3:0];
  wire [2:0] col;
  assign col = sub[3:1];  // glyph column 0..4 (valid when sub < 10)

  // character codes (see vga_font.v)
  localparam [4:0] SP = 5'd0, A = 5'd1, C = 5'd2, E = 5'd3, G = 5'd4, H = 5'd5, M = 5'd6,
                   N = 5'd7, O = 5'd8, P = 5'd9, R = 5'd10, S = 5'd11, T = 5'd12,
                   V = 5'd13, Y = 5'd14, D0 = 5'd15;

  reg [4:0] code;
  always @(*) begin
    code = SP;
    if (in_start) begin
      if (line == 2'd0)  // RHYTHM GAME
        case (idx)
          5'd0: code = R;  5'd1: code = H;  5'd2: code = Y;  5'd3: code = T;
          5'd4: code = H;  5'd5: code = M;  5'd7: code = G;  5'd8: code = A;
          5'd9: code = M;  5'd10: code = E;
          default: code = SP;
        endcase
      else  // PRESS ENTER
        case (idx)
          5'd0: code = P;  5'd1: code = R;  5'd2: code = E;  5'd3: code = S;
          5'd4: code = S;  5'd6: code = E;  5'd7: code = N;  5'd8: code = T;
          5'd9: code = E;  5'd10: code = R;
          default: code = SP;
        endcase
    end
    else begin
      if (line == 2'd0)  // GAME OVER
        case (idx)
          5'd0: code = G;  5'd1: code = A;  5'd2: code = M;  5'd3: code = E;
          5'd5: code = O;  5'd6: code = V;  5'd7: code = E;  5'd8: code = R;
          default: code = SP;
        endcase
      else if (line == 2'd1)  // SCORE tens ones
        case (idx)
          5'd0: code = S;  5'd1: code = C;  5'd2: code = O;  5'd3: code = R;
          5'd4: code = E;
          5'd6: code = D0 + hundreds;
          5'd7: code = D0 + tens;
          5'd8: code = D0 + ones;
          default: code = SP;
        endcase
      else  // PRESS SPACE
        case (idx)
          5'd0: code = P;  5'd1: code = R;  5'd2: code = E;  5'd3: code = S;
          5'd4: code = S;  5'd6: code = S;  5'd7: code = P;  5'd8: code = A;
          5'd9: code = C;  5'd10: code = E;
          default: code = SP;
        endcase
    end
  end

  wire [4:0] bits;
  vga_font F (.code(code), .row(glyph_row), .bits(bits));

  wire in_glyph;
  assign in_glyph = in_line && (x >= x0) && (sub < 10);

  wire text_pixel;
  assign text_pixel = in_glyph && bits[3'd4 - col];

  // text colour per line
  wire [8:0] text_color;
  assign text_color = in_start ? (line == 2'd0 ? YELLOW : WHITE) :
                      (line == 2'd0 ? RED : (line == 2'd1 ? CYAN : WHITE));

  // final colour
  assign color = bar_pixel ? bar_color :
                 in_play ? board_color :
                 text_pixel ? text_color : BG;

endmodule