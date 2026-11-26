// note_chart.v

// note chart ROM: step = number of scroll ticks since the song started
// spawn[i] high puts a new note at the top of lane i on that step
// total: 99 notes, one per step (no chords), last spawn at step 571
// song: 600 steps 

module note_chart (step, spawn);

  input [9:0] step;
  output reg [3:0] spawn;

  always @(*) begin
    case (step)
      10'd4: spawn = 4'b0100; 
      10'd10: spawn = 4'b0001;
      10'd16: spawn = 4'b0100;
      10'd22: spawn = 4'b1000;
      10'd28: spawn = 4'b0001;
      10'd34: spawn = 4'b0010;
      10'd40: spawn = 4'b1000;
      10'd43: spawn = 4'b0001;
      10'd49: spawn = 4'b0100;
      10'd55: spawn = 4'b1000;
      10'd61: spawn = 4'b0001;
      10'd67: spawn = 4'b1000;
      10'd73: spawn = 4'b0001;
      10'd79: spawn = 4'b0010;
      10'd85: spawn = 4'b0001;
      10'd91: spawn = 4'b0100;
      10'd97: spawn = 4'b0010;
      10'd103: spawn = 4'b0001;
      10'd109: spawn = 4'b0010;
      10'd115: spawn = 4'b0001;
      10'd121: spawn = 4'b1000;
      10'd124: spawn = 4'b0010;
      10'd130: spawn = 4'b0001;
      10'd136: spawn = 4'b1000;
      10'd142: spawn = 4'b0001;
      10'd148: spawn = 4'b0010;
      10'd154: spawn = 4'b1000;
      10'd160: spawn = 4'b0100;
      10'd166: spawn = 4'b1000;
      10'd172: spawn = 4'b0001;
      10'd178: spawn = 4'b1000;
      10'd184: spawn = 4'b0100;
      10'd190: spawn = 4'b0010;
      10'd196: spawn = 4'b0001;
      10'd202: spawn = 4'b0010;
      10'd205: spawn = 4'b0001;
      10'd211: spawn = 4'b1000;
      10'd217: spawn = 4'b0001;
      10'd223: spawn = 4'b0100;
      10'd229: spawn = 4'b0010;
      10'd235: spawn = 4'b0001;
      10'd241: spawn = 4'b1000;
      10'd247: spawn = 4'b0001;
      10'd253: spawn = 4'b1000;
      10'd259: spawn = 4'b0010;
      10'd265: spawn = 4'b1000;
      10'd271: spawn = 4'b0100;
      10'd277: spawn = 4'b0001;
      10'd283: spawn = 4'b0010;
      10'd286: spawn = 4'b1000;
      10'd292: spawn = 4'b0100;
      10'd298: spawn = 4'b1000;
      10'd304: spawn = 4'b0001;
      10'd310: spawn = 4'b0100;
      10'd316: spawn = 4'b0001;
      10'd322: spawn = 4'b1000;
      10'd328: spawn = 4'b0100;
      10'd334: spawn = 4'b0001;
      10'd340: spawn = 4'b1000;
      10'd346: spawn = 4'b0001;
      10'd352: spawn = 4'b1000;
      10'd358: spawn = 4'b0001;
      10'd364: spawn = 4'b0100;
      10'd367: spawn = 4'b1000;
      10'd373: spawn = 4'b0100;
      10'd379: spawn = 4'b0010;
      10'd385: spawn = 4'b0100;
      10'd391: spawn = 4'b0010;
      10'd397: spawn = 4'b1000;
      10'd403: spawn = 4'b0010;
      10'd409: spawn = 4'b0100;
      10'd415: spawn = 4'b0010;
      10'd421: spawn = 4'b0001;
      10'd427: spawn = 4'b0010;
      10'd433: spawn = 4'b1000;
      10'd439: spawn = 4'b0001;
      10'd445: spawn = 4'b0010;
      10'd448: spawn = 4'b1000;
      10'd454: spawn = 4'b0010;
      10'd460: spawn = 4'b1000;
      10'd466: spawn = 4'b0010;
      10'd472: spawn = 4'b0100;
      10'd478: spawn = 4'b1000;
      10'd484: spawn = 4'b0010;
      10'd490: spawn = 4'b0100;
      10'd496: spawn = 4'b1000;
      10'd502: spawn = 4'b0001;
      10'd508: spawn = 4'b0010;
      10'd514: spawn = 4'b1000;
      10'd520: spawn = 4'b0010;
      10'd526: spawn = 4'b0001;
      10'd529: spawn = 4'b0100;
      10'd535: spawn = 4'b0001;
      10'd541: spawn = 4'b0100;
      10'd547: spawn = 4'b0010;
      10'd553: spawn = 4'b0001;
      10'd559: spawn = 4'b1000;
      10'd565: spawn = 4'b0001;
      10'd571: spawn = 4'b1000;
      default: spawn = 4'b0000;
    endcase
  end
  
endmodule