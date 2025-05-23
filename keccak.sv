import keccak_pkg::*;

module keccak (
    // Master signals
    input  logic clk,
    input  logic rst,

    // Control input signals
    input  logic ready_in,
    input  logic valid_in,
    // Control input signals
    output  logic ready_out,
    output  logic valid_out,

    // Data input signals
    input logic[w-1:0] data_in,

    // Data output signals
    output logic[w-1:0] data_out
);

    // Changing polarity to be coherent with reference_code
    logic valid_in_internal;
    logic ready_in_internal;

    // First stage signals
    logic[RATE_SHAKE128-1:0] rate_input;
    logic[31:0] output_size;
    logic[1:0] operation_mode;
    logic input_buffer_ready_wr;
    logic input_buffer_ready;
    logic last_block_in_buffer_wr;
    logic last_block_in_buffer;

    // Second-third stage signals
    logic input_buffer_ready_clr;
    logic last_block_in_buffer_clr;


    // Polarity change
    assign valid_in_internal = !valid_in;
    assign ready_in_internal = !ready_in;


    // First pipeline stage
    load_stage load_pipeline_stage (
        .clk                     (clk),
        .rst                     (rst),
        .valid_in                (valid_in_internal),
        .data_in                 (data_in),
        .input_buffer_out        (rate_input),
        .output_size             (output_size),
        .operation_mode          (operation_mode),
        .input_buffer_ready      (input_buffer_ready),
        .input_buffer_ready_wr   (input_buffer_ready_wr),
        .last_block_in_buffer_wr (last_block_in_buffer_wr),
        .ready_out               (ready_out)
    );

    // Signaling between first and second stage
    latch input_buffer_ready_latch (
        .clk (clk),
        .set (input_buffer_ready_wr),
        .rst (input_buffer_ready_clr || rst),
        .q   (input_buffer_ready)
    );
    latch last_block_in_buffer_latch (
        .clk (clk),
        .set (last_block_in_buffer_wr),
        .rst (last_block_in_buffer_clr || rst),
        .q   (last_block_in_buffer)
    );

    // Shared second and third pipeline stages
    permute_dump_stage permute_dump_pipeline_stage (
        .clk                       (clk),
        .rst                       (rst),
        .output_size               (output_size),
        .rate_input                (rate_input),
        .operation_mode            (operation_mode),
        .input_buffer_ready        (input_buffer_ready),
        .last_block_in_buffer      (last_block_in_buffer),
        .input_buffer_ready_clr    (input_buffer_ready_clr),
        .last_block_in_buffer_clr  (last_block_in_buffer_clr),
        .ready_in                  (ready_in_internal),
        .data_out                  (data_out),
        .valid_out                 (valid_out)
    );

endmodule