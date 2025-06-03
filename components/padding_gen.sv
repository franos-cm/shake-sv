`timescale 1ns / 1ps

import keccak_pkg::*;

module padding_generator (
    // Data in
    input  logic  clk,
    input logic[w-1:0] data_in,

    // Control signals
    input logic [w_byte_width:0] remaining_valid_bytes, // How many of the input bytes are valid
    input logic padding_enable,                         // Flag if padding is already needed
    input logic last_word_in_block,                     // Flag if current word is last of block
    input logic padding_reset,                          // Flag to reset padding latches

    // Data out
    output logic last_block,
    output logic[w-1:0] data_out
);
    // Domain separator for SHAKE, is appended just after message 
    localparam logic [7:0] DOMAIN_SEPARATOR_BYTE = 8'h1F;
    // Final byte when padding has multiple bytes
    localparam logic [7:0] TERMINATOR_PADDING_BYTE = 8'h80;
    // Used in edge case when the last byte has both the domain separator, and the 10*1 padding
    localparam logic [7:0] COMPLETE_PADDING_BYTE = 8'h9F;
    
    logic [w_byte_size-1:0] first_pad_word_sel;
    logic [w_byte_size-1:0] padding_mask_sel;
    logic [7:0] byte_pad[w_byte_size-1:0];
    logic first_pad_used;


    // Latch to know if the first pad has already been used
    latch first_pad_used_latch (
        .clk (clk),
        .set (padding_enable),
        .rst (padding_reset),
        .q   (first_pad_used)
    );

    // Decide what the padding should be for each byte. NOTE: lookup tables might be better
    assign first_pad_word_sel = (padding_enable && !first_pad_used) ? (8'b1000_0000 >> remaining_valid_bytes) : '0;
    assign padding_mask_sel = padding_enable ? (8'hFF >> remaining_valid_bytes) : '0;
    // Decide when the first_pad has been applied
    assign last_block = padding_enable || first_pad_used;

    always_comb begin
        // Select DOMAIN_SEPARATOR_BYTE for the first padded byte of the word
        for (int i = 1; i < w_byte_size; i++)
            byte_pad[i] = (first_pad_word_sel[i]) ? DOMAIN_SEPARATOR_BYTE : '0;

        case ({last_word_in_block, first_pad_word_sel[0]})
            2'b00:     byte_pad[0] = 8'b0;
            2'b01:     byte_pad[0] = DOMAIN_SEPARATOR_BYTE;   
            2'b10:     byte_pad[0] = TERMINATOR_PADDING_BYTE;   
            2'b11:     byte_pad[0] = COMPLETE_PADDING_BYTE;   
        endcase

        for (int i = 0; i < w_byte_size; i++)
            data_out[(i+1)*8-1 -: 8] = padding_mask_sel[i] ? byte_pad[i] : data_in[(i+1)*8-1 -: 8];
    end


endmodule