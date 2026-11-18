// lane.v

// stores lane's current notes：notes[14:0]
// top of the screen: bit 0, bottom of the screen: bit 14. 1 if note exists
// moves notes down on scroll_tick high
// hit if in slot 11, 12, 13. 

module lane (clock, resetn, enable, scroll_tick, spawn, press, notes, hit, miss);

  input clock, resetn, enable, scroll_tick, spawn, press;
  output reg [14:0] notes;
  output reg hit, miss;

  // only react at key press (holding only reacts once)
  reg press_prev;
  wire press_pulse;
  assign press_pulse = press & ~press_prev;

  // hit window check: slot 11, 12, 13
  wire in_window;
  assign in_window = notes[11] | notes[12] | notes[13];

  wire hit_now;
  assign hit_now = press_pulse & in_window;

  // removing the lowest note on the screen within the hit window
  wire [14:0] remove;
  assign remove = notes[13] ? 15'b010_0000_0000_0000 :  // slot 13
                  notes[12] ? 15'b001_0000_0000_0000 :  // slot 12
                              15'b000_1000_0000_0000;  // slot 11

  wire [14:0] after_hit;  // notes to keep
  assign after_hit = hit_now ? (notes & ~remove) : notes;

  // if there is a note about to get missed
  wire miss_now;
  assign miss_now = scroll_tick & after_hit[14];

  always @(posedge clock) begin
    press_prev <= press;
    if (!resetn || !enable) begin
      notes <= 15'd0;
      hit <= 1'b0;
      miss <= 1'b0;
    end
    else begin
      if (scroll_tick)
        notes <= {after_hit[13:0], spawn};  // shift down, new note enters at top
      else
        notes <= after_hit;
      hit <= hit_now;
      miss <= miss_now;
    end
  end

endmodule