import keccak_pkg::*;


module load_datapath (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic[w-1:0] data_in,

    // Control signals
    input  logic control_regs_enable,
    input  logic load_enable,
    input  logic padding_enable,
    input  logic padding_reset,
    input  logic input_counter_en,
    input  logic input_counter_load,

    // Status signals
    output logic input_buffer_full,
    output logic input_size_reached,
    output logic first_incomplete_input_word,
    output logic last_input_block,

    // Outputs for next pipeline stage
    output logic[1:0] operation_mode,
    output logic[RATE_SHAKE128-1:0] rate_input,
    output logic[31:0] output_size
);
    // ---------- Internal signals declaration ----------
    //
    logic last_word_in_block;
    logic [4:0] input_buffer_counter;
    logic [31:0] input_size_counter;
    logic [4:0] max_buffer_depth;
    logic[w_byte_width:0] remaining_valid_bytes; // goes from 0 to 8
    logic last_input_word;
    logic [w-1:0] padded_data;    // Data after it's been padded
    logic [w-1:0] padded_data_le; // Little endian representation


    // ------------------- Components -------------------
    //
    // Operation mode reg, to decide current block size
    regn #(
        .WIDTH(2)
    ) op_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (control_regs_enable),
        .data_in (data_in[62:61]), // NOTE: only these middle bits are needed, since those are the ones that change
        .data_out (operation_mode)
    );

    // Output size reg, to transmit to next pipeline stage
    regn #(
        .WIDTH(32)
    ) output_size_reg (
        .clk  (clk),
        .rst (rst),
        .en (control_regs_enable),
        .data_in ({4'b0, data_in[59:32]}),
        .data_out (output_size)
    );

    // Input size counter
    size_counter #(
        .WIDTH(32),
        .w(w)
    ) input_size_left (
        .clk (clk),
        .rst (rst),
        .data_in(data_in[31:0]),
        .en_write(control_regs_enable),
        .step_size(w),
        .en_count(load_enable),
        .last_word(last_input_word),
        .counter_end(input_size_reached),
        .counter(input_size_counter)
        // The block_size input doesnt really matter here.
        // That is, since we need to account for padding,
        // last_block is driven by the padding generator.
    );

    // Padding Generator
    // NOTE: doing this in a parametric way possibly makes it more confusing
    assign remaining_valid_bytes = input_size_counter[w_bit_width:3];
    assign first_incomplete_input_word = last_input_word && (remaining_valid_bytes != w_byte_size);
    // NOTE: hacky way of subtracting 1 from odd number, but it should simplify synthesis
    assign last_word_in_block = (input_buffer_counter == {max_buffer_depth[4:1], 1'b0});
    padding_generator padding_gen (
        .clk (clk),
        .data_in (data_in),
        .remaining_valid_bytes(remaining_valid_bytes),
        .padding_enable(padding_enable),
        .last_word_in_block(last_word_in_block),
        .padding_reset(padding_reset),
        .last_block(last_input_block),
        .data_out(padded_data)
    );

    // Counter for input buffer: corresponds to how many positions are filled
    countern #(
        .WIDTH(5)
    ) input_counter (
        .clk  (clk),
        .rst (rst),
        .en (input_counter_en),
        .load_max (input_counter_load),
        .max_count (max_buffer_depth),
        .count_end (input_buffer_full),
        .counter(input_buffer_counter)
    );


    // Serial-in, Parallel-out buffer for input,
    // after its been padded and had its endianness switched
    sipo_buffer #(
        .WIDTH(w),
        .DEPTH(RATE_SHAKE128/w)
    ) input_buffer(
        .clk (clk),
        .rst (rst),
        .en (load_enable),
        .data_in (padded_data_le),
        .data_out (rate_input)
    );


    // ------------ Combinatorial assignments -----------
    //
    // Decide block size based on current operation mode
    always_comb begin
        unique case (operation_mode)
            SHAKE256_MODE_VEC: max_buffer_depth = 5'd17;
            SHAKE128_MODE_VEC: max_buffer_depth = 5'd21;
            default: max_buffer_depth = 5'd21;
        endcase
    end

    // Input transformations
    assign padded_data_le = EndianSwitcher#(w)::switch(padded_data);

endmodule