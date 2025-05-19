import keccak_pkg::w;

module keccak (
    // Master signals
    input  logic clk,
    input  logic rst,

    // Control input signals
    input  logic ready_i,
    input  logic valid_i,
    // Control input signals
    output  logic ready_o,
    output  logic valid_o,

    // Data input signals
    input logic[w-1:0] data_in,

    // Data output signals
    output logic[w-1:0] data_out
);

    // First stage signals
    logic[RATE_SHAKE128-1:0] input_buffer_out;
    logic[31:0] output_size;
    logic[1:0] operation_mode;
    logic input_buffer_ready_wr;
    logic input_buffer_ready;
    logic last_block_in_buffer_wr;
    logic last_block_in_buffer;

    // Second stage signals
    logic[RATE_SHAKE128-1:0] output_buffer_in;
    logic output_buffer_we;
    logic output_buffer_ready;
    logic input_buffer_ready_clr;
    logic last_block_in_buffer_clr;

    // First pipeline stage
    load_stage load_pipeline_stage (
        .clk                     (clk),
        .rst                     (rst),
        .valid_i                 (valid_i),
        .data_in                 (data_in),
        .input_buffer_out        (input_buffer_out),
        .output_size             (output_size),
        .operation_mode          (operation_mode),
        .input_buffer_ready_wr   (input_buffer_ready_wr),
        .last_block_in_buffer_wr (last_block_in_buffer_wr),
        .ready_o                 (ready_o)
    );

    // Signaling between first and second stage
    latch input_buffer_ready (
        .clk (clk),
        .rst (input_buffer_ready_clr),
        .set (input_buffer_ready_wr),
        .q   (input_buffer_ready)
    )
    latch last_block_in_buffer (
        .clk (clk),
        .rst (last_block_in_buffer_clr),
        .set (last_block_in_buffer_wr),
        .q   (last_block_in_buffer)
    )

    // First pipeline stage
    permute_stage permute_pipeline_stage (
        .clk                       (clk),
        .rst                       (rst),
        .rate_input                (input_buffer_out),
        .output_size               (output_size),
        .operation_mode            (operation_mode),
        .rate_output               (output_buffer_in),
        .output_buffer_we          (output_buffer_we),
        .input_buffer_ready        (input_buffer_ready),
        .last_block_in_buffer      (last_block_in_buffer),
        .output_buffer_ready       (output_buffer_ready),
        .input_buffer_ready_clr    (input_buffer_ready_clr),
        .last_block_in_buffer_clr  (last_block_in_buffer_clr)
    );

endmodule