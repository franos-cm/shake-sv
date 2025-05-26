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
    logic valid_in_internal, ready_in_internal;

    // First to second stage data signals
    logic[RATE_SHAKE128-1:0] rate_input;
    logic[1:0] operation_mode_load_stage;
    logic[31:0] output_size_load_stage;

    // Second to third stage data signals
    logic[RATE_SHAKE128-1:0] rate_output;
    logic[1:0] operation_mode_permute_stage;
    logic[31:0] output_size_permute_stage;
    logic output_buffer_we;

    // Handshaking signals
    logic input_buffer_ready, input_buffer_ready_wr, input_buffer_ready_clr;
    logic last_output_block, last_output_block_wr, last_output_block_clr;
    logic output_buffer_available, output_buffer_available_wr, output_buffer_available_clr;
    logic last_block_in_buffer, last_block_in_buffer_wr, last_block_in_buffer_clr;


    // Polarity change
    assign valid_in_internal = !valid_in;
    assign ready_in_internal = !ready_in;


    // First pipeline stage
    load_stage load_pipeline_stage (
        // External inputs
        .clk                     (clk),
        .rst                     (rst),
        .valid_in                (valid_in_internal),
        .data_in                 (data_in),
        // Outputs for next stage
        .rate_input              (rate_input),
        .operation_mode          (operation_mode_load_stage),
        .output_size             (output_size_load_stage),
        // External outputs
        .ready_out               (ready_out),
        // Second stage pipeline handshaking
        .input_buffer_ready      (input_buffer_ready),
        .input_buffer_ready_wr   (input_buffer_ready_wr),
        .last_block_in_buffer_wr (last_block_in_buffer_wr)
    );

    // Signaling between first and second stage
    latch input_buffer_ready_latch (
        .clk (clk),
        .set (input_buffer_ready_wr),
        .rst (input_buffer_ready_clr),
        .q   (input_buffer_ready)
    );
    latch last_block_in_buffer_latch (
        .clk (clk),
        .set (last_block_in_buffer_wr),
        .rst (last_block_in_buffer_clr),
        .q   (last_block_in_buffer)
    );

    // Second pipeline stage
    permute_stage permute_pipeline_stage (
        // External inputs
        .clk                          (clk),
        .rst                          (rst),
        // Inputs from previous stage
        .rate_input                   (rate_input),
        .operation_mode_in            (operation_mode_load_stage),
        .output_size_in               (output_size_load_stage),
        // Outputs for next stage
        .rate_output                  (rate_output),
        .operation_mode_out           (operation_mode_permute_stage),
        .output_size_out              (output_size_permute_stage),
        .output_buffer_we             (output_buffer_we),
        // First stage pipeline handshaking
        .input_buffer_ready           (input_buffer_ready),
        .input_buffer_ready_clr       (input_buffer_ready_clr),
        .last_block_in_buffer         (last_block_in_buffer),
        .last_block_in_buffer_clr     (last_block_in_buffer_clr),
        // Third stage pipeline handshaking
        .output_buffer_available      (output_buffer_available),
        .output_buffer_available_clr  (output_buffer_available_clr),
        .last_output_block_wr         (last_output_block_wr)
    );

    // Signaling between second and third stage
    latch output_buffer_available_latch (
        .clk (clk),
        .set (output_buffer_available_wr),
        .rst (output_buffer_available_clr),
        .q   (output_buffer_available)
    );
    latch last_output_block_latch (
        .clk (clk),
        .set (last_output_block_wr),
        .rst (last_output_block_clr),
        .q   (last_output_block)
    );

    // Third pipeline stage
    dump_stage dump_pipeline_stage (
        // External inputs
        .clk                         (clk),
        .rst                         (rst),
        .ready_in                    (ready_in_internal),
        // Inputs from previous stage
        .rate_output                 (rate_output),
        .operation_mode              (operation_mode_permute_stage),
        .output_size                 (output_size_permute_stage),
        .output_buffer_we            (output_buffer_we),
        // External outputs
        .data_out                    (data_out),
        .valid_out                   (valid_out),
        // Second stage pipeline handshaking
        .last_output_block           (last_output_block),
        .last_output_block_clr       (last_output_block_clr),
        .output_buffer_available_wr  (output_buffer_available_wr)
    );


endmodule