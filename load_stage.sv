import keccak_pkg::*;

module load_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic valid_i,
    input logic[w-1:0] data_in,
        
    // Inputs for next stage
    output logic[RATE_SHAKE128-1:0] input_buffer_out,
    output logic[31:0] output_size,
    output logic[1:0] operation_mode,

    // Pipeline handshaking
    output logic input_buffer_ready_wr,
    output logic last_block_in_buffer_wr,

    // External outputs
    output  logic ready_o
);
    logic input_buffer_empty;
    logic input_buffer_full;
    logic last_input_block;
    logic load_enable;
    logic control_regs_enable;

    load_fsm load_stage_fsm (
        .clk                     (clk),
        .rst                     (rst),
        .valid_i                 (valid_i),
        .input_buffer_empty      (input_buffer_empty),
        .input_buffer_full       (input_buffer_full),
        .last_input_block        (last_input_block),
        .ready_o                 (ready_o),
        .load_enable             (load_enable),
        .control_regs_enable     (control_regs_enable),
        .input_buffer_ready_wr   (input_buffer_ready_wr),
        .last_block_in_buffer_wr (last_block_in_buffer_wr)
    );

    load_datapath load_stage_datapath (
        .clk                 (clk),
        .rst                 (rst),
        .load_enable         (load_enable),
        .control_regs_enable (control_regs_enable),
        .data_in             (data_in),
        .input_buffer_empty  (input_buffer_empty),
        .input_buffer_full   (input_buffer_full),
        .last_input_block    (last_input_block),
        .input_buffer_out    (input_buffer_out),
        .output_size         (output_size),
        .operation_mode      (operation_mode)
    );

endmodule