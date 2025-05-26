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
    output logic counter_end,
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
    assign counter_end = (_counter == '0);
    assign counter = _counter;
endmodule