`timescale 1ns/1ps
import keccak_pkg::*;

module keccak_tb;
    logic clk;
    logic rst;
    logic valid_i, ready_i;
    logic[w-1:0] data_in;
    wire[w-1:0] data_out;
    wire ready_o, valid_o;

    keccak dut (
        .clk(clk),
        .rst(rst),
        .valid_i(valid_i),
        .ready_i(ready_i),
        .data_in(data_in),
        .ready_o(ready_o),
        .valid_o(valid_o),
        .data_out(data_out)
    );

    // Clock generation
    initial clk = 1;
    always #5 clk = ~clk;

    initial begin
        rst <= 1;
        valid_i <= 0;
        ready_i <= 1;
        data_in <= 0;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (1) @(posedge clk);
        valid_i <= 1; data_in <= 64'h8000010000000020;
        repeat (1) @(posedge clk);
        valid_i <= 1; data_in <= 64'h0615502300000000;
        repeat (1) @(posedge clk);
        data_in <= 64'h0000000000000000;
        repeat (16) @(posedge clk);
        valid_i <= 0;
        #400;
        repeat (1) @(posedge clk);
        ready_o <= 1;
        #200;
        $stop;
    end
endmodule