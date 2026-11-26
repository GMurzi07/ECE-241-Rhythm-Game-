
module audio_tone (
    input clock,
    input resetn,
    input [3:0] hit,
    input audio_out_allowed,
    output reg write_audio_out,
    output reg [31:0] left
);

parameter HP0 = 92;
parameter HP1 = 73;
parameter HP2 = 61;
parameter HP3 = 46;
parameter NOTE_SAMPLES = 6000;

parameter AMP_POS = 32'h10000000;
parameter AMP_NEG = 32'hF0000000;

reg [7:0] half_period;
reg [7:0] cnt;
reg [12:0] remaining;
reg sign;
reg [31:0] left_temp;

wire any_hit = |hit;
wire playing = (remaining != 0);

always @(*) begin
    write_audio_out = audio_out_allowed;

    if (playing) begin
        if (sign)
            left_temp = AMP_POS;
        else
            left_temp = AMP_NEG;
    end
    else begin
        left_temp = 32'b0;
    end

    left = left_temp;
end

always @(posedge clock) begin
    if (!resetn) begin
        half_period <= HP0;
        cnt <= 0;
        remaining <= 0;
        sign <= 0;
    end
    else if (any_hit) begin
        if (hit[0])
            half_period <= HP0;
        else if (hit[1])
            half_period <= HP1;
        else if (hit[2])
            half_period <= HP2;
        else
            half_period <= HP3;

        remaining <= NOTE_SAMPLES;
        cnt <= 0;
    end
    else if (audio_out_allowed && playing) begin
        remaining <= remaining - 1;

        if (cnt >= half_period - 1) begin
            cnt <= 0;
            sign <= ~sign;
        end
        else begin
            cnt <= cnt + 1;
        end
    end
end

endmodule
