`timescale 1ns / 1ps

module round_constant_generator #(
    parameter int w = 64
) (
    input  logic[4:0]     round_num,
    output logic[w-1:0]   round_constant
);

    logic[w-1:0]   _round_constant;

    always_comb begin
    unique case (round_num)
        5'b00000: _round_constant = 64'h0000000000000001;
        5'b00001: _round_constant = 64'h0000000000008082;
        5'b00010: _round_constant = 64'h800000000000808A;
        5'b00011: _round_constant = 64'h8000000080008000;
        5'b00100: _round_constant = 64'h000000000000808B;
        5'b00101: _round_constant = 64'h0000000080000001;
        5'b00110: _round_constant = 64'h8000000080008081;
        5'b00111: _round_constant = 64'h8000000000008009;
        5'b01000: _round_constant = 64'h000000000000008A;
        5'b01001: _round_constant = 64'h0000000000000088;
        5'b01010: _round_constant = 64'h0000000080008009;
        5'b01011: _round_constant = 64'h000000008000000A;
        5'b01100: _round_constant = 64'h000000008000808B;
        5'b01101: _round_constant = 64'h800000000000008B;
        5'b01110: _round_constant = 64'h8000000000008089;
        5'b01111: _round_constant = 64'h8000000000008003;
        5'b10000: _round_constant = 64'h8000000000008002;
        5'b10001: _round_constant = 64'h8000000000000080;
        5'b10010: _round_constant = 64'h000000000000800A;
        5'b10011: _round_constant = 64'h800000008000000A;
        5'b10100: _round_constant = 64'h8000000080008081;
        5'b10101: _round_constant = 64'h8000000000008080;
        5'b10110: _round_constant = 64'h0000000080000001;
        5'b10111: _round_constant = 64'h8000000080008008;
        default:  _round_constant = 64'h0000000000000000;
    endcase
    end

    assign round_constant = _round_constant[w-1:0];

endmodule