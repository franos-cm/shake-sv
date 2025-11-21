`timescale 1ns / 1ps

module regn #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1:0] INIT = '0
) (
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] data_o
);
    always_ff @(posedge clk) begin
        if (rst)
            data_o <= INIT;
        else if (en)
            data_o <= data_i;
    end

endmodule
