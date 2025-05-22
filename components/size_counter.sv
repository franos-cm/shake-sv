import keccak_pkg::*;

module size_counter #(
    parameter int WIDTH = 32,
    parameter int w = 64
) (
    input  logic  clk,
    input  logic  rst,
    input  logic [WIDTH-1:0] data_in,
    input  logic  en_write,
    input  logic [WIDTH-1:0] step_size,
    input  logic  en_count,
    input  logic[10:0] block_size,

    output logic last_word,
    output logic last_block,
    output logic [WIDTH-1:0] counter
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

    assign last_word = (_counter <= w);
    assign last_block = (_counter <= block_size);
endmodule


// import keccak_pkg::*;

// module size_counter #(
//     parameter int WIDTH = 32,
//     parameter int w = 64
// ) (
//     input  logic  clk,
//     input  logic  rst,
//     input  logic  en_write,
//     input  logic  en_count,
//     input  logic  batch_count,
//     input  logic[WIDTH-1:0] block_size,
//     input  logic[WIDTH-1:0] word_size,
//     input  logic[WIDTH-1:0] data_in,

//     output logic last_block,
//     output logic incomplete_block,
//     output logic last_word,
//     output logic incomplete_word,
//     output logic[$clog2(w)-1:0] last_word_remainder
// );
//     logic [WIDTH-1:0] _counter;
//     logic [WIDTH-1:0] _decrease_step;

//     // TODO: reg this, instead of combinatorial?
//     assign _decrease_step = batch_count ? block_size : word_size;

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst)
//             _counter <= '1;
//         else if (en_write)
//             _counter <= data_in;
//         else if (en_count) begin
//             if (_counter < _decrease_step)
//                 _counter <= '0;
//             else
//                 _counter <= _counter - _decrease_step;
//         end 
//     end

//     assign last_block = (_counter <= block_size);
//     assign incomplete_block = (_counter < block_size);
//     assign last_word = (_counter <= w); // TODO: not sure this conversion works
//     assign incomplete_word = (_counter < w); // TODO: not sure this conversion works
//     assign last_word_remainder = _counter[($clog2(w)-1):0];
// endmodule