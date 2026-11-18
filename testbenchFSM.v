`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20; // 50 MHz clock

	reg clk, resetn, start_key, advance_key;
	wire tick, song_done;
	wire [15:0] frame_count;
	wire in_start, in_play, in_gameover, timer_run, timer_clear;

	initial begin
		clk <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) clk <= ~clk; //Wait half clk period and invert 
	end

	initial begin
		resetn = 0; start_key = 0; advance_key = 0;
		#40  resetn = 1;  // release reset -> START
		#60  start_key = 1;   // press start -> PLAY
		#40  start_key = 0;
	    #1000 advance_key = 1; // song is over -> press advance
		#40  advance_key = 0; // back to START
		#60  start_key = 1;  // play again
		#40  start_key = 0;
	    #400 resetn = 0; // reset in the middle of the song
		#40  resetn = 1;
		#100 $stop;
	end 

	// Small values so the simulation is short (real: 833333 and 3600)
	frame_tick #(.CLKS_PER_FRAME(4)) U1 (clk, resetn, tick);
	song_timer #(.SONG_FRAMES(10)) U2 (clk, resetn, tick, timer_run, timer_clear, frame_count, song_done);
	game_fsm U3 (clk, resetn, start_key, advance_key, song_done,
	             in_start, in_play, in_gameover, timer_run, timer_clear);

endmodule