import keccak_pkg::w;

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
    logic[RATE_SHAKE128-1:0] input_buffer_out;
    logic[31:0] output_size;
    logic[1:0] operation_mode_lp;
    logic input_buffer_ready_wr;
    logic input_buffer_ready;
    logic last_block_in_buffer_wr;
    logic last_block_in_buffer;

    // Second stage signals
    logic[RATE_SHAKE128-1:0] output_buffer_in;
    logic[1:0] operation_mode_pd;
    logic output_buffer_we;
    logic output_buffer_available;
    logic input_buffer_ready_clr;
    logic last_block_in_buffer_clr;

    // Third stage signals
    logic output_buffer_available_wr;


    // Polarity change
    assign valid_in_internal = !valid_in;
    assign ready_in_internal = !ready_in;


    // First pipeline stage
    load_stage load_pipeline_stage (
        .clk                     (clk),
        .rst                     (rst),
        .valid_in                (valid_in_internal),
        .data_in                 (data_in),
        .input_buffer_out        (input_buffer_out),
        .output_size             (output_size),
        .operation_mode          (operation_mode_lp),
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

    // Second pipeline stage
    permute_stage permute_pipeline_stage (
        .clk                       (clk),
        .rst                       (rst),
        .rate_input                (input_buffer_out),
        .output_size               (output_size),
        .operation_mode_in         (operation_mode_lp),
        .operation_mode_out        (operation_mode_pd),
        .rate_output               (output_buffer_in),
        .output_buffer_we          (output_buffer_we),
        .input_buffer_ready        (input_buffer_ready),
        .last_block_in_buffer      (last_block_in_buffer),
        .output_buffer_available   (output_buffer_available),
        .input_buffer_ready_clr    (input_buffer_ready_clr),
        .last_block_in_buffer_clr  (last_block_in_buffer_clr)
    );

    // Signaling between second and third stage
    latch output_buffer_available_latch (
        .clk (clk),
        .set (output_buffer_available_wr),
        .rst (output_buffer_we || rst),
        .q   (output_buffer_available)
    );

    // Third pipeline stage
    dump_stage dump_pipeline_stage (
        .clk                         (clk),
        .rst                         (rst),
        .ready_in                    (ready_in_internal),
        .output_buffer_in            (output_buffer_in),
        .operation_mode              (operation_mode_pd),
        .output_buffer_we            (output_buffer_we),
        .data_out                    (data_out),
        .valid_out                   (valid_out), 
        .output_buffer_available_wr  (output_buffer_available_wr)
    );

endmodule