// score_display.v

// score_counter: two digit decimal counter, max. 99
module score_counter (clock, resetn, hit, ones, tens);

  input clock, resetn, hit;
  output reg [3:0] ones, tens;

  always @(posedge clock) begin
    if (!resetn) begin
      ones <= 4'd0;
      tens <= 4'd0;
    end
    else if (hit) begin
      if (ones == 4'd9) begin
        if (tens != 4'd9) begin
          ones <= 4'd0;
          tens <= tens + 1'b1;
        end
      end
      else
        ones <= ones + 1'b1;
    end
  end

endmodule


// hex7seg: lookup table for the HEX display
module hex7seg (digit, hex);

  input [3:0] digit;
  output reg [6:0] hex;

  always @(*) begin
    case (digit)
      4'd0: hex = 7'b1000000;
      4'd1: hex = 7'b1111001;
      4'd2: hex = 7'b0100100;
      4'd3: hex = 7'b0110000;
      4'd4: hex = 7'b0011001;
      4'd5: hex = 7'b0010010;
      4'd6: hex = 7'b0000010;
      4'd7: hex = 7'b1111000;
      4'd8: hex = 7'b0000000;
      4'd9: hex = 7'b0010000;
      default: hex = 7'b1111111;
    endcase
  end

endmodule