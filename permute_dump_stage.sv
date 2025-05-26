import keccak_pkg::*;

// TODO: divide these in two stages
module permute_dump_stage (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic ready_in,

    // Inputs from previous stage
    input logic[RATE_SHAKE128-1:0] rate_input,
    input logic[31:0] output_size,
    input logic[1:0] operation_mode,

    // External outputs
    output logic[w-1:0] data_out,
    output logic valid_out,

    // Pipeline handshaking
    input logic input_buffer_ready,
    input logic last_block_in_buffer,
    output logic input_buffer_ready_clr,
    output logic last_block_in_buffer_clr
);
    logic round_count_load;
    logic round_done;
    logic round_start;
    logic last_output_block;
    logic absorb_enable;
    logic round_en;
    logic output_buffer_we;

    logic copy_control_regs_en;
    logic output_size_reached;
    logic output_buffer_empty;
    logic output_counter_rst;
    logic output_buffer_available;
    logic output_buffer_available_wr;

    logic output_counter_load;
    logic output_buffer_shift_en;
    logic state_reset;

    // TODO: Get rid of these when we divide this into two stages
    logic last_output_block_reg;
    logic last_output_block_dump;
    logic last_output_block_wr;
    logic last_output_block_clr;

    logic valid_bytes_enable;
    logic valid_bytes_reset;


    permute_fsm permute_stage_fsm (
        .clk                        (clk),
        .rst                        (rst),
        .copy_control_regs_en       (copy_control_regs_en),
        .input_buffer_ready         (input_buffer_ready),
        .last_block_in_input_buffer (last_block_in_buffer),
        .round_count_load           (round_count_load),
        .round_done                 (round_done),
        .round_start                (round_start),
        .output_buffer_available    (output_buffer_available),
        .last_output_block          (last_output_block),
        .absorb_enable              (absorb_enable),
        .round_en                   (round_en),
        .output_buffer_we           (output_buffer_we),
        .input_buffer_ready_clr     (input_buffer_ready_clr),
        .last_block_in_buffer_clr   (last_block_in_buffer_clr),
        .last_output_block_wr       (last_output_block_wr),
        .state_reset                (state_reset)
    );

    // Signaling between second and third stage
    latch output_buffer_available_latch (
        .clk (clk),
        .set (output_buffer_available_wr),
        .rst (output_buffer_we || rst),
        .q   (output_buffer_available)
    );

    // Signaling between second and third stage
    latch last_output_block_latch (
        .clk (clk),
        .set (last_output_block_wr),
        .rst (last_output_block_clr || rst),
        .q   (last_output_block_reg)
    );

    dump_fsm dump_stage_fsm (
        .clk                         (clk),
        .rst                         (rst),
        .ready_in                    (ready_in),
        .output_buffer_we            (output_buffer_we),
        .output_buffer_empty         (output_buffer_empty),
        .output_size_reached         (output_size_reached),
        .last_output_block_in        (last_output_block_reg),
        .output_counter_load         (output_counter_load),
        .output_counter_rst          (output_counter_rst),
        .output_buffer_shift_en      (output_buffer_shift_en),
        .output_buffer_available_wr  (output_buffer_available_wr),
        .last_output_block_clr       (last_output_block_clr),
        .valid_bytes_reset           (valid_bytes_reset),
        .valid_bytes_enable          (valid_bytes_enable),
        .last_output_block           (last_output_block_dump),
        .valid_out                   (valid_out)
    );

    permute_dump_datapath permute_dump_stage_datapath (
        .clk                     (clk),
        .rst                     (rst),
        .copy_control_regs_en    (copy_control_regs_en),
        .absorb_enable           (absorb_enable),
        .round_en                (round_en),
        .rate_input              (rate_input),
        .output_size_in          (output_size),
        .operation_mode_in       (operation_mode),
        .round_count_load        (round_count_load),
        .round_start             (round_start),
        .round_done              (round_done),
        .last_output_block       (last_output_block),
        .output_size_reached     (output_size_reached),
        .output_buffer_we        (output_buffer_we),
        .output_buffer_shift_en  (output_buffer_shift_en),
        .output_counter_load     (output_counter_load),
        .output_counter_rst      (output_counter_rst),
        .output_buffer_empty     (output_buffer_empty),
        .data_out                (data_out),
        .state_reset             (state_reset),
        .valid_bytes_reset       (valid_bytes_reset),
        .valid_bytes_enable      (valid_bytes_enable),

        .last_output_block_dump  (last_output_block_dump)
    );

endmodule