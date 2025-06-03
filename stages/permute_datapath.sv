`timescale 1ns / 1ps

import keccak_pkg::*;

module permute_datapath (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous pipeline stage
    input  logic[RATE_SHAKE128-1:0] rate_input,
    input  logic[1:0] operation_mode_in,
    input  logic[31:0] output_size_in,

    // Control signals
    input  logic copy_control_data,
    input  logic absorb_enable,
    input  logic round_en,
    input  logic round_count_load,
    input  logic output_size_count_en,
    input  logic state_reset,

    // Status signals
    output logic round_start,
    output logic round_done,
    output logic last_output_block,

    // Outputs for next pipeline stage
    output logic[RATE_SHAKE128-1:0] rate_output,
    output logic[1:0] operation_mode_out,
    output logic[31:0] output_size_out,
    output logic buffer_ready_clr_delay
);
    // ---------- Internal signals declaration ----------
    //
    logic[1:0] operation_mode_reg;
    logic[10:0] block_size;

    logic[$clog2(24)-1:0] round_num;
    logic[w-1:0] round_constant;
    logic[STATE_WIDTH-1:0] state_reg_in;
    logic[STATE_WIDTH-1:0] state_reg_out;
    logic[STATE_WIDTH-1:0] round_in;
    logic[STATE_WIDTH-1:0] xor_mask;


    // ----------------- Components -----------------
    //
    // Reg for current mode, coming from previous stage
    regn #(
        .WIDTH(2)
    ) op_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (copy_control_data),
        .data_in (operation_mode_in),
        .data_out (operation_mode_reg)
    );


    // Round number counter
    countern #(
        .WIDTH(5) 
    ) round_counter (
        .clk (clk),
        .rst (rst),
        .en (round_en),
        .load_max (round_count_load),
        .max_count(5'd23),
        .counter(round_num),
        .count_start(round_start),
        .count_end(round_done)
    );
    assign buffer_ready_clr_delay = (round_num == 5'd5);

    // Round number to constant mapper
    round_constant_generator round_constant_gen (
        .round_num  (round_num),
        .round_constant (round_constant)
    );

    // State reg
    regn #(
        .WIDTH(STATE_WIDTH)
    ) state_reg (
        .clk  (clk),
        .rst (state_reset),
        .en (round_en),
        .data_in (state_reg_in),
        .data_out (state_reg_out)
    );

    // Keccak round
    keccak_round round(
        .rin(round_in),
        .rc(round_constant),
        .rout(state_reg_in)
    );

    // Output size counter
    size_counter #(
        .WIDTH(32),
        .w(w)
    ) output_size_left (
        .clk (clk),
        .rst (rst),
        .en_write(copy_control_data),
        .en_count(output_size_count_en),
        .block_size(block_size),
        .step_size({21'b0, block_size}),
        .data_in(output_size_in),
        .last_block(last_output_block),
        .counter(output_size_out)
    );


    // ------------- Combinatorial assignments -------------
    //
    // Enables absorption of input by the keccak round
    always_comb begin
        if (!absorb_enable)
            xor_mask = '0;
        else if (operation_mode_out == SHAKE256_MODE_VEC)
            xor_mask = {rate_input[RATE_SHAKE256-1 : 0], {CAP_SHAKE256{1'b0}}};
        else if (operation_mode_out == SHAKE128_MODE_VEC)
            xor_mask = {rate_input[RATE_SHAKE128-1 : 0], {CAP_SHAKE128{1'b0}}};
        else
            xor_mask = '0;

    end
    assign round_in = state_reg_out ^ xor_mask;
    
    // Decide block size based on current operation mode
    always_comb begin
        unique case (operation_mode_out)
            SHAKE256_MODE_VEC : block_size = RATE_SHAKE256_VEC;
            SHAKE128_MODE_VEC : block_size = RATE_SHAKE128_VEC;
            default: block_size = '0;
        endcase
    end

    // NOTE: kind of a hacky way of enable passthrough so we can
    // get the correct value of operation mode in the first absorb
    assign operation_mode_out = copy_control_data ? operation_mode_in : operation_mode_reg;
    
    // Permute output assignment
    assign rate_output = EndianSwitcher#(RATE_SHAKE128)::switch(state_reg_out[STATE_WIDTH-1 -: RATE_SHAKE128]);

endmodule