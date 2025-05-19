import keccak_pkg::*;

module size_counter #(
    parameter int WIDTH = 32,
    parameter int w = 64
) (
    input  logic  clk,
    input  logic  rst,
    input  logic  en_write,
    input  logic  en_count,
    input  logic[10:0] block_size,
    input  logic[WIDTH-1:0] step_size,
    input  logic[WIDTH-1:0] data_in,

    output logic last_word,
    output logic last_block,
    output logic[$clog2(w)-1:0] last_word_remainder
);
    logic [WIDTH-1:0] _counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            _counter <= '1;
        else if (en_write)
            _counter <= data_in;
        else if (en_count) begin
            if (_counter < step_size)
                _counter <= '0;
            else
                _counter <= _counter - step_size;
        end 
    end

    assign last_word = (_counter <= w); // TOOD: not sur ethis conversion works
    // remainder is only useful during last_word... maybe not the most intuitive design
    assign last_word_remainder = _counter[($clog2(w)-1):0];
    assign last_block = (_counter <= block_size);
endmodule