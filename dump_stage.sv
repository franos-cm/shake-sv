import keccak_pkg::*;

module dump_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic ready_in,

    // Inputs from previous stage
    input  logic[RATE_SHAKE128-1:0] rate_output,
    input  logic[31:0] output_size,
    input  logic[1:0] operation_mode,
    input  logic output_buffer_we,

    // Outputs for next stage
    output logic[w-1:0] data_out,
    output logic valid_out,

    // Second stage pipeline handshaking
    input  logic last_output_block,
    output logic last_output_block_clr,
    output logic output_buffer_available_wr
);
    logic output_buffer_shift_en;
    logic output_buffer_empty;
    logic output_counter_rst, output_counter_load;
    logic valid_bytes_enable, valid_bytes_reset;
    logic last_output_block_internal, output_buffer_we_internal;

    dump_fsm dump_stage_fsm (
        // External inputs
        .clk                         (clk),
        .rst                         (rst),
        .ready_in                    (ready_in),
        // Inputs from previous stage
        .output_buffer_we_in         (output_buffer_we),
        .last_output_block_in        (last_output_block),
        // Status signals
        .output_buffer_empty         (output_buffer_empty),
        // Control signals
        .output_counter_load         (output_counter_load),
        .output_counter_rst          (output_counter_rst),
        .output_buffer_shift_en      (output_buffer_shift_en),
        .valid_bytes_reset           (valid_bytes_reset),
        .valid_bytes_enable          (valid_bytes_enable),
        .last_output_block_out       (last_output_block_internal),
        .output_buffer_we_out        (output_buffer_we_internal),
        // Pipeline handshaking
        .output_buffer_available_wr  (output_buffer_available_wr),
        .last_output_block_clr       (last_output_block_clr),
        // External outputs
        .valid_out                   (valid_out)
    );

    dump_datapath dump_stage_datapath (
        // External inputs
        .clk                     (clk),
        .rst                     (rst),
        // Inputs from previous stage
        .rate_output             (rate_output),
        .output_size             (output_size),
        .operation_mode          (operation_mode),
        // Control signals
        .output_buffer_we        (output_buffer_we_internal),
        .last_output_block       (last_output_block_internal),
        .output_buffer_shift_en  (output_buffer_shift_en),
        .output_counter_load     (output_counter_load),
        .output_counter_rst      (output_counter_rst),
        .valid_bytes_reset       (valid_bytes_reset),
        .valid_bytes_enable      (valid_bytes_enable),
        // Status signals
        .output_buffer_empty     (output_buffer_empty),
        // External outputs
        .data_out                (data_out)
    );

endmodule