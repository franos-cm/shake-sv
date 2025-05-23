import keccak_pkg::*;

module load_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input logic[w-1:0] data_in,
        
    // Inputs for next stage
    output logic[RATE_SHAKE128-1:0] input_buffer_out,
    output logic[31:0] output_size,
    output logic[1:0] operation_mode,

    // Pipeline handshaking
    input  logic input_buffer_ready,
    output logic input_buffer_ready_wr,
    output logic last_block_in_buffer_wr,

    // External outputs
    output  logic ready_out
);
    logic input_buffer_full;
    logic last_valid_input_word;
    logic input_size_reached;
    logic last_input_block;
    logic load_enable;
    logic control_regs_enable;
    logic padding_enable;
    logic padding_reset;
    logic input_counter_en;
    logic input_counter_load;

    load_fsm load_stage_fsm (
        .clk                     (clk),
        .rst                     (rst),
        .valid_in                (valid_in),
        .input_buffer_ready      (input_buffer_ready),
        .input_buffer_full       (input_buffer_full),
        .last_valid_input_word   (last_valid_input_word),
        .last_input_block        (last_input_block),
        .input_size_reached      (input_size_reached),
        .ready_out               (ready_out),
        .load_enable             (load_enable),
        .control_regs_enable     (control_regs_enable),
        .input_buffer_ready_wr   (input_buffer_ready_wr),
        .last_block_in_buffer_wr (last_block_in_buffer_wr),
        .padding_enable          (padding_enable),
        .padding_reset           (padding_reset),
        .input_counter_en        (input_counter_en),
        .input_counter_load      (input_counter_load)
    );

    load_datapath load_stage_datapath (
        .clk                     (clk),
        .rst                     (rst),
        .data_in                 (data_in),
        .load_enable             (load_enable),
        .control_regs_enable     (control_regs_enable),
        .input_buffer_full       (input_buffer_full),
        .input_size_reached      (input_size_reached),
        .last_valid_input_word   (last_valid_input_word),
        .last_input_block        (last_input_block),
        .input_buffer_out        (input_buffer_out),
        .output_size             (output_size),
        .operation_mode          (operation_mode),
        .padding_enable          (padding_enable),
        .padding_reset           (padding_reset),
        .input_counter_en        (input_counter_en),
        .input_counter_load      (input_counter_load)
    );

endmodule