import keccak_pkg::*;


module keccak_datapath (
    input  logic clk,
    input  logic rst,
    input logic control_regs_enable,
    input logic absorb_enable,
    input logic round_count_en,
    input logic round_count_reset,
    input logic input_buffer_we,
    input logic output_buffer_we,
    input logic output_buffer_se,
    input logic state_enable,
    input logic[w-1:0] data_in,

    output logic input_buffer_full,
    output logic round_done,
    output logic last_input_word,
    output logic last_output_word,
    output logic last_output_block,
    output logic output_buffer_empty;
    output logic[w-1:0] data_out
);
    logic[3:0] operation_mode;

    // Round
    logic[1599:0] state_reg_in;
    logic[1599:0] state_reg_out;
    logic [1087:0] input_buffer_out;

    // Round counter
    logic[$clog2(24)-1:0] round_num;

    // Round constant gen
    logic[w-1:0] round_constant;
    
    // Sipo and Piso
    logic[w-1:0] input_data_in;

    // Sipo and Piso counter
    logic input_counter_enable;
    logic output_counter_enable;

    logic[10:0]  block_size;


    regn #(
        .N(4)
    ) operation_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (control_regs_enable),
        .data_in (data_in[63:60]),
        .data_out (operation_mode)
    );

    // TODO: change this to real values
    always_comb begin
        unique case (operation_mode)
            2'b00 : block_size = RATE_SHAKE256;
            2'b01 : block_size = RATE_SHAKE128;
            2'b00:  block_size = '0;
        endcase
    end

    size_counter #(
        .WIDTH(32)
    ) input_size_left (
        .clk (clk),
        .rst (rst),
        .block_size(block_size),
        .en_write(control_regs_enable),
        .en_count(input_buffer_we),
        .data_in(data_in[31:0]),
        .last_word(last_input_word)
    );

    // TODO: add param to subtract a whole block at once?
    size_counter #(
        .WIDTH(28)
    ) output_size_left (
        .clk (clk),
        .rst (rst),
        .block_size(block_size),
        .en_write(control_regs_enable),
        .en_count(output_buffer_se),
        .data_in(data_in[59:32]),
        .last_word(last_output_word),
        .last_block(last_output_block)
    );

    assign input_counter_enable = input_buffer_we || absorb_enable;
    countern #(
        .N(18)
    ) input_counter (
        .clk  (clk),
        .rst (rst),
        .en (input_counter_enable),
        .count_up (1),
        .count_end (input_buffer_full)
    );


    // padding_generator #(
    //     .WIDTH(w),
    // ) padding_gen (
    //     .clk(clk),
    //     .rst(rst),
    // )

    assign input_data_in = data_in;

    sipo_buffer #(
        .WIDTH(w),
        .DEPTH(17)
    ) input_buffer(
        .clk (clk),
        .rst (rst),
        .en (input_buffer_we),
        .data_in (input_data_in),
        .data_out (input_buffer_out)
    );

    countern #(
        .N(25)
    ) round_counter (
        .clk  (clk),
        .rst (round_count_reset),
        .en (round_count_en),
        .count_up (1),
        .counter(round_num),
        .count_end(round_done)
    );

    round_constant_generator round_constant_gen (
        .round_num  (round_num),
        .round_constant (round_constant)
    );

    regn #(
        .N(1600)
    ) state_reg (
        .clk  (clk),
        .rst (rst),
        .en (state_enable),
        .data_in (state_reg_in),
        .data_out (state_reg_out)
    );

    
    // This module essentially exists to make the netlist prettier
    k_state round_in;
    k_state round_out;
    absorber round_converter(
        .absorb_enable(absorb_enable),
        .rate_data(input_buffer_out),
        .state_reg_in(state_reg_in),
        .state_reg_out(state_reg_out),
        .round_in(round_in),
        .round_out(round_out)
    );


    keccak_f keccak_function(
        .round_in(round_in),
        .round_constant_signal(round_constant),
        .round_out(round_out)
    );


    // This feels kinda counter-intuitive...
    // It works because the we signal puts the counter to 17 again,
    // so it works like a way of inputting the initial value
    assign output_counter_enable = output_buffer_we || output_buffer_se;
    countern #(
        .N(18)
    ) output_counter (
        .clk  (clk),
        .rst (rst),
        .en (output_counter_enable),
        .count_up (0),
        .count_start (output_buffer_empty)
    );

    piso_buffer #(
        .WIDTH(w),
        .DEPTH(17)
    ) output_buffer(
        .clk (clk),
        .rst (rst),
        .write_enable (output_buffer_we),
        // .write_enable (output_buffer_we),
        .data_in (state_reg_out[1087:0]),
        .data_out (data_out)
    );


endmodule