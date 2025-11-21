import keccak_pkg::*;


module keccak (
    // Master signals
    input  logic clk,
    input  logic rst,

    // Control input signals
    input  logic ready_o,
    input  logic valid_i,
    // Control input signals
    output  logic ready_i,
    output  logic valid_o,

    // Data input signals
    input logic[w-1:0] data_i,
    // Data output signals
    output logic[w-1:0] data_o
);

    // Changing polarity to be coherent with reference_code
    logic valid_i_internal, ready_o_internal;

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
    assign valid_i_internal = !valid_i;
    assign ready_o_internal = !ready_o;


    // First pipeline stage
    load_stage load_pipeline_stage (
        // External inputs
        .clk                     (clk),
        .rst                     (rst),
        .valid_i                (valid_i_internal),
        .data_i                 (data_i),
        // Outputs for next stage
        .rate_input              (rate_input),
        .operation_mode          (operation_mode_load_stage),
        .output_size             (output_size_load_stage),
        // External outputs
        .ready_i               (ready_i),
        // Second stage pipeline handshaking
        .input_buffer_ready      (input_buffer_ready && !input_buffer_ready_clr), // NOTE: passthrough of clear signal
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
        .ready_o                    (ready_o_internal),
        // Inputs from previous stage
        .rate_output                 (rate_output),
        .operation_mode              (operation_mode_permute_stage),
        .output_size                 (output_size_permute_stage),
        .output_buffer_we            (output_buffer_we),
        // External outputs
        .data_o                    (data_o),
        .valid_o                   (valid_o),
        // Second stage pipeline handshaking
        .last_output_block           (last_output_block),
        .last_output_block_clr       (last_output_block_clr),
        .output_buffer_available_wr  (output_buffer_available_wr)
    );


endmodule