import keccak_pkg::*;

module dump_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic ready_in,
        
    // Inputs from previous stage
    input logic[RATE_SHAKE128-1:0] output_buffer_in,
    input logic[1:0] operation_mode,
    input logic output_buffer_we,

    // External outputs
    output logic[w-1:0] data_out,
    output logic valid_out,

    // Pipeline handshaking
    output logic output_buffer_available_wr
);
    logic output_buffer_empty;
    logic output_counter_load;
    logic output_counter_rst;
    logic output_buffer_shift_en;
    logic output_buffer_we_internal;

    dump_fsm dump_stage_fsm (
        .clk                         (clk),
        .rst                         (rst),
        .ready_in                    (ready_in),
        .valid_out                   (valid_out),
        .output_buffer_we_in         (output_buffer_we),
        .output_buffer_we_out        (output_buffer_we_internal),
        .output_buffer_empty         (output_buffer_empty),
        .output_counter_load         (output_counter_load),
        .output_counter_rst          (output_counter_rst),
        .output_buffer_shift_en      (output_buffer_shift_en),
        .output_buffer_available_wr  (output_buffer_available_wr)
    );

    dump_datapath dump_stage_datapath (
        .clk                     (clk),
        .rst                     (rst),
        .output_buffer_in        (output_buffer_in),
        .operation_mode          (operation_mode),
        .output_buffer_we        (output_buffer_we_internal),
        .output_counter_load     (output_counter_load),
        .output_counter_rst      (output_counter_rst),
        .output_buffer_shift_en  (output_buffer_shift_en),
        .output_buffer_empty     (output_buffer_empty),
        .data_out                (data_out)
    );

endmodule