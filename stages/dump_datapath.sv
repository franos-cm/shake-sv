import keccak_pkg::*;


module dump_datapath (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous pipeline stage
    input  logic[RATE_SHAKE128-1:0] rate_output,
    input  logic[31:0] output_size,
    input  logic[1:0] operation_mode,

    // Control signals
    input  logic output_buffer_we,
    input  logic last_output_block,
    input  logic output_buffer_shift_en,
    input  logic output_counter_load,
    input  logic output_counter_rst,
    input  logic valid_bytes_reset,
    input  logic valid_bytes_enable,

    // Status signals
    output logic output_buffer_empty,

    // External outputs
    output logic[w-1:0] data_out
);
    // ---------- Internal signals declaration ----------
    //
    logic [4:0] max_buffer_depth;
    logic [4:0] remaining_valid_words;
    logic [4:0] extra_valid_word;

    logic[w_byte_width-1:0] remaining_valid_bytes, remaining_valid_bytes_reg;  // NOTE: goes from 0 to 7
    logic[w-1:0] buffer_output;
    logic[w_byte_size-1:0] zero_mask_sel;
    logic last_word_from_block;


    // -------------------- Components --------------------
    //
    // Counter for output buffer
    countern #(
        .WIDTH(5)
    ) output_counter (
        .clk  (clk),
        .rst (output_counter_rst),
        .en (output_buffer_shift_en),
        .load_max (output_counter_load),
        .max_count (max_buffer_depth),
        .count_last (last_word_from_block),
        .count_end (output_buffer_empty)
    );

    // Reg for output masking
    // TODO: the slices here are really confusing, which has to do with the definition of w_bit_width. Change this.
    assign remaining_valid_bytes = output_size[w_bit_width-1:3];
    regn #(
        .WIDTH(w_bit_width - 3)
    ) output_bytes_reg (
        .clk  (clk),
        .rst (valid_bytes_reset),
        .en (valid_bytes_enable),
        .data_in (remaining_valid_bytes),
        .data_out (remaining_valid_bytes_reg)
    );

    piso_buffer #(
        .WIDTH(w),
        .DEPTH(RATE_SHAKE128/w)
    ) output_buffer(
        .clk (clk),
        .rst (rst),
        .write_enable (output_buffer_we),
        .shift_enable (output_buffer_shift_en),
        .data_in (rate_output),
        .data_out (buffer_output)
    );

    // ----------------- Combinatorial assignments -----------------
    //

    // Decide how many words will there be in the buffer
    assign extra_valid_word = remaining_valid_bytes ? 5'd1 : 5'd0;
    assign remaining_valid_words = output_size[w_bit_width+5:w_bit_width] + extra_valid_word;
    always_comb begin
        if (last_output_block)
            max_buffer_depth = remaining_valid_words[4:0];
        else if (operation_mode == SHAKE256_MODE_VEC)
            max_buffer_depth = 5'd17;
        else 
            max_buffer_depth = 5'd21;
    end

    // Zero mask when last word is not complete
    assign zero_mask_sel = (last_word_from_block && remaining_valid_bytes_reg) ? (8'hFF >> remaining_valid_bytes_reg) : '0;
    always_comb begin
        for (int i = 0; i < w_byte_size; i++)
            data_out[(i+1)*8-1 -: 8] = zero_mask_sel[i] ? 8'h00 : buffer_output[(i+1)*8-1 -: 8];
    end

endmodule