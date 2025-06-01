`timescale 1ns / 1ps

module latch (
    input  logic clk,
    input  logic rst,    // synchronous reset
    input  logic set,    // pulse this high to latch a 1
    output logic q       // latched output
);
    always_ff @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else if (set)
            q <= 1'b1;
    end
endmodule
