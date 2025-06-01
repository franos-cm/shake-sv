`timescale 1ns / 1ps

module countern #(
    parameter int WIDTH = 32
) (
    input  logic  clk,
    input  logic  rst,
    input  logic  en,
    input  logic  load_max,
    input  logic[WIDTH-1:0] max_count,

    output logic[WIDTH-1:0] counter,
    output logic count_end,
    output logic count_last,
    output logic count_start
);
    logic [WIDTH-1:0] _max_count;
    logic [WIDTH-1:0] _counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            _counter <= '0;
            _max_count <= '1;
        end
        else begin
            if (load_max)
                _max_count <= max_count;
            else if (en)
                _counter <= _counter == _max_count ? '0 : _counter + 1;
        end
            
    end

    assign counter = _counter;
    assign count_start = _counter == '0;
    assign count_last = _counter == (_max_count - 1);
    assign count_end = _counter == _max_count;

endmodule