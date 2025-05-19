import keccak_pkg::*;

module permute_stage (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous stage
    input logic[RATE_SHAKE128-1:0] rate_input,
    input logic[31:0] output_size,
    input logic[1:0] operation_mode,
    input logic copy_control_regs_en,

    // Outputs for next stage
    output logic[RATE_SHAKE128-1:0] rate_output,
    output logic output_buffer_we,

    // Pipeline handshaking
    input logic input_buffer_ready,
    input logic last_block_in_buffer,
    input logic output_buffer_ready,
    output logic input_buffer_ready_clr,
    output logic last_block_in_buffer_clr
);
    logic round_done;
    logic last_output_block;
    logic absorb_enable;
    logic round_en;

    logic last_input_block;
    logic load_enable;
    logic control_regs_enable;

    permute_fsm permute_stage_fsm (
        .clk                        (clk),
        .rst                        (rst),
        .input_buffer_ready         (input_buffer_ready),
        .last_block_in_input_buffer (last_block_in_buffer),
        .round_done                 (input_buffer_full),
        .output_buffer_ready        (output_buffer_ready),
        .absorb_enable              (absorb_enable),
        .round_en                   (round_en),
        .output_buffer_we           (output_buffer_we),
        .input_buffer_ready_clr     (input_buffer_ready_clr),
        .last_block_in_buffer_clr   (last_block_in_buffer_clr)
    );

    permute_datapath permute_stage_datapath (
        .clk                  (clk),
        .rst                  (rst),
        .copy_control_regs_en (copy_control_regs_en),
        .absorb_enable        (absorb_enable),
        .round_en             (round_en),
        .rate_input           (rate_input),
        .output_size_in       (output_size),
        .operation_mode_in    (operation_mode),
        .round_done           (round_done),
        .last_output_block    (last_output_block),
        .rate_output          (rate_output)
    );

endmodule