/* DE1-SoC wrapper (top-level entity): connects game.v to the DE1-SoC vga_adapter.
 * Press KEY[0] to reset. This game is 320x240. */
module vga_demo(CLOCK_50, SW, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
                VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    parameter RESOLUTION = "320x240";   // this game is 320x240 only
    parameter nX = 9;                   // 320 wide -> 9 bits
    parameter nY = 8;                   // 240 tall -> 8 bits

    input  wire CLOCK_50;
    input  wire [9:0] SW;
    input  wire [3:0] KEY;
    output wire [9:0] LEDR;
    output wire [6:0] HEX0;
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    wire [nX-1:0] X;
    wire [nY-1:0] Y;
    wire [8:0] color;
    wire write;

    // real-board timing: the defaults in game.v (60 frames per second)
    game G (.CLOCK_50(CLOCK_50), .SW(SW), .KEY(KEY), .LEDR(LEDR),
            .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
            .x(X), .y(Y), .color(color), .write(write));
        defparam G.nX = nX;
        defparam G.nY = nY;

    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(color),
        .x(X),
        .y(Y),
        .write(write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = RESOLUTION;
        // If your DE1-SoC adapter has a COLOR_DEPTH / BITS_PER_COLOUR_CHANNEL parameter,
        // keep it at 9-bit (3 bits per channel). Remove any defparam it doesn't have.
        defparam VGA.BACKGROUND_IMAGE = (RESOLUTION == "320x240") ? "./MIF/black_320_9.mif"
                                                                  : "./MIF/black_160_9.mif";
endmodule