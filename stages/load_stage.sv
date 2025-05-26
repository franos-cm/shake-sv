import keccak_pkg::*;


module load_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input logic[w-1:0] data_in,
        
    // Inputs for next stage
    output logic[RATE_SHAKE128-1:0] rate_input,
    output logic[31:0] output_size,
    output logic[1:0] operation_mode,

    // External outputs
    output logic ready_out,

    // Pipeline handshaking
    input  logic input_buffer_ready,
    output logic input_buffer_ready_wr,
    output logic last_block_in_buffer_wr
);

    // Control signals
    logic control_regs_enable;
    logic padding_reset, padding_enable;
    logic input_counter_load, input_counter_en;
    logic load_enable;

    // Status signals
    logic input_buffer_full;
    logic first_incomplete_input_word;
    logic input_size_reached;
    logic last_input_block;


    load_fsm load_stage_fsm (
        // External inputs
        .clk                           (clk),
        .rst                           (rst),
        .valid_in                      (valid_in),
        // Status signals
        .input_buffer_full             (input_buffer_full),
        .first_incomplete_input_word   (first_incomplete_input_word),
        .last_input_block              (last_input_block),
        .input_size_reached            (input_size_reached),
        // Control signals
        .control_regs_enable           (control_regs_enable),
        .load_enable                   (load_enable),
        .input_counter_en              (input_counter_en),
        .input_counter_load            (input_counter_load),
        .padding_enable                (padding_enable),
        .padding_reset                 (padding_reset),
        // Second stage pipeline handshaking
        .input_buffer_ready            (input_buffer_ready),
        .input_buffer_ready_wr         (input_buffer_ready_wr),
        .last_block_in_buffer_wr       (last_block_in_buffer_wr),
        // External outputs
        .ready_out                     (ready_out)
    );

    load_datapath load_stage_datapath (
        // External inputs
        .clk                           (clk),
        .rst                           (rst),
        .data_in                       (data_in),
        // Control signals
        .control_regs_enable           (control_regs_enable),
        .load_enable                   (load_enable),
        .padding_enable                (padding_enable),
        .padding_reset                 (padding_reset),
        .input_counter_en              (input_counter_en),
        .input_counter_load            (input_counter_load),
        // Status signals
        .input_buffer_full             (input_buffer_full),
        .input_size_reached            (input_size_reached),
        .first_incomplete_input_word   (first_incomplete_input_word),
        .last_input_block              (last_input_block),
        // Outputs for next pipeline stage
        .rate_input                    (rate_input),
        .operation_mode                (operation_mode),
        .output_size                   (output_size)
    );

endmodule