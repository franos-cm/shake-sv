import keccak_pkg::*;

module dump_datapath (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous stage
    input logic [RATE_SHAKE128-1:0] output_buffer_in,
    input logic[31:0] output_size_counter,
    input logic [1:0] operation_mode,
    input logic output_buffer_we,
    input logic last_output_block,

    // Control inputs
    input logic output_counter_load,
    input logic output_counter_rst,
    input logic output_buffer_shift_en,

    // Control outputs
    output logic output_buffer_empty,

    // External output
    output logic[w-1:0] data_out
);
    // ---------- Internal signals declaration ----------
    //
    logic [4:0] max_buffer_depth;
    logic [31 - w_bit_width:0] remaining_valid_words;
    logic[w_byte_width-1:0] remaining_valid_bytes;


    // ------------------- Components -------------------
    //

    // Counter for output buffer
    countern #(
        .WIDTH(5)
    ) output_counter (
        .clk  (clk),
        .rst (output_counter_rst), // TODO: not sure if needed
        .en (output_buffer_shift_en),
        .load_max (output_counter_load),
        .max_count (max_buffer_depth),
        .count_end(output_buffer_empty)
    );

    piso_buffer #(
        .WIDTH(w),
        .DEPTH(RATE_SHAKE128/w)
    ) output_buffer(
        .clk (clk),
        .rst (rst),
        .write_enable (output_buffer_we),
        .shift_enable (output_buffer_shift_en),
        .data_in (output_buffer_in),
        .data_out (data_out)
    );

    // ------------ Combinatorial assignments -----------
    //
    always_comb begin
        if (last_output_block)
            max_buffer_depth = remaining_valid_words;
        else if (operation_mode == SHAKE256_MODE_VEC)
            max_buffer_depth = 5'd17;
        else 
            max_buffer_depth = 5'd21;
    end

    // LEFT HERE: pick right slice
    assign remaining_valid_words = output_size_counter[31:w_bit_width];
    assign remaining_valid_bytes = output_size_counter[(w_bit_width-1):3];

endmodule