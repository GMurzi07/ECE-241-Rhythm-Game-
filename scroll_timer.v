// scroll_timer.v

// turns the frame_tick (FSM.v) into a slower pulse, scroll_tick. 
// the notes move down one slot on every scroll_tick. 
// TEMPORARY: game.v has a simple frame_tick until integration of modules.

module scroll_timer (clock, resetn, frame_tick, scroll_tick);

  parameter FRAMES_PER_STEP = 6;  // max. 15 (counter: 4 bits)

  input clock, resetn, frame_tick;
  output scroll_tick;

  reg [3:0] frames;  // frame counter 

  assign scroll_tick = frame_tick && (frames == FRAMES_PER_STEP - 1);

  always @(posedge clock) begin
    if (!resetn)
      frames <= 4'd0;
    else if (frame_tick) begin
      if (frames == FRAMES_PER_STEP - 1)
        frames <= 4'd0;
      else
        frames <= frames + 1'b1;
    end
  end

endmodule