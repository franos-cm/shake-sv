import keccak_pkg::*;

module padding_generator #(
    parameter int WIDTH = 32,
    parameter int bytes_in_block =  64
) (
    input  logic  clk,
    input  logic  rst,
    input  logic[WIDTH-1:0]  input_byte_size,
    output logic[w-1:0] padding
);
    logic [WIDTH-1:0] _counter;
    localparam int byte_delta = w / 8;

    countern #(
        .n(17)
    ) counter_mod_17 (
        .clk  (clk),
        .rst (rst),
        .en  (en_count),
        .count_up (1'b0)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            _counter <= '0;
    end

    assign input_bytes_left = _counter[($clog2(bytes_in_block)-1):0];
    assign last_block = (_counter <= byte_delta);
endmodule