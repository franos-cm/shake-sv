`timescale 1ns / 1ps

import keccak_pkg::*;

module permute_stage (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous pipeline stage
    input logic[RATE_SHAKE128-1:0] rate_input,
    input logic[1:0] operation_mode_in,
    input logic[31:0] output_size_in,

    // Outputs for next pipeline stage
    output logic[RATE_SHAKE128-1:0] rate_output,
    output logic[1:0] operation_mode_out,
    output logic[31:0] output_size_out,
    output logic output_buffer_we,

    // First stage pipeline handshaking
    input logic input_buffer_ready,
    input logic last_block_in_buffer,
    output logic input_buffer_ready_clr,
    output logic last_block_in_buffer_clr,

    // Third stage pipeline handshaking
    input  logic output_buffer_available,
    output logic output_buffer_available_clr,
    output logic last_output_block_wr
);
    
    // Control signals
    logic state_reset;
    logic copy_control_data;
    logic absorb_enable;
    logic round_en;
    logic output_size_count_en;
    logic round_count_load;

    // Status signals
    logic round_done;
    logic round_start;
    logic last_output_block;
    logic buffer_ready_clr_delay;


    permute_fsm permute_stage_fsm (
        // External inputs
        .clk                          (clk),
        .rst                          (rst),
        // Status signals
        .round_start                  (round_start),
        .round_done                   (round_done),
        .last_output_block            (last_output_block),
        // Control signals
        .state_reset                  (state_reset),
        .copy_control_data            (copy_control_data),
        .absorb_enable                (absorb_enable),
        .round_en                     (round_en),
        .round_count_load             (round_count_load),
        .output_size_count_en         (output_size_count_en),
        // First stage pipeline handshaking
        .input_buffer_ready           (input_buffer_ready),
        .input_buffer_ready_clr       (input_buffer_ready_clr),
        .last_block_in_input_buffer   (last_block_in_buffer),
        .last_block_in_buffer_clr     (last_block_in_buffer_clr),
        // Second stage pipeline handshaking
        .output_buffer_available      (output_buffer_available),
        .output_buffer_available_clr  (output_buffer_available_clr),
        .last_output_block_wr         (last_output_block_wr),
        .output_buffer_we             (output_buffer_we),
        .buffer_ready_clr_delay       (buffer_ready_clr_delay)
    );


    permute_datapath permute_stage_datapath (
        // External inputs
        .clk                     (clk),
        .rst                     (rst),
        // Inputs from previous pipeline stage
        .rate_input              (rate_input),
        .operation_mode_in       (operation_mode_in),
        .output_size_in          (output_size_in),
        // Control signals
        .copy_control_data       (copy_control_data),
        .absorb_enable           (absorb_enable),
        .round_en                (round_en),
        .round_count_load        (round_count_load),
        .output_size_count_en    (output_size_count_en),
        .state_reset             (state_reset),
        // Status signals
        .round_start             (round_start),
        .round_done              (round_done),
        .last_output_block       (last_output_block),
        // Outputs for next pipeline stage
        .rate_output             (rate_output),
        .operation_mode_out      (operation_mode_out),
        .output_size_out         (output_size_out),
        .buffer_ready_clr_delay  (buffer_ready_clr_delay)

    );

endmodule