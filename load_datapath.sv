import keccak_pkg::*;


module load_datapath (
    input  logic clk,
    input  logic rst,
    input  logic load_enable,
    input  logic control_regs_enable,
    input  logic padding_enable,
    input  logic padding_reset,
    input  logic[w-1:0] data_in,

    output logic last_valid_input_word,
    output logic input_buffer_empty,
    output logic input_buffer_full,
    output logic last_input_block,
    output logic[RATE_SHAKE128-1:0] input_buffer_out,
    output logic[31:0] output_size,
    output logic[1:0] operation_mode
);
    // ---------- Internal signals declaration ----------
    //
    logic last_word_in_block;
    logic [4:0] input_buffer_counter;
    logic [31:0] input_size_counter;
    logic [1:0] operation_mode_reg;
    logic [4:0] max_buffer_depth;
    logic[w_byte_width-1:0] remaining_valid_bytes;
    logic [w-1:0] padded_data;    // Data after its been padded
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
        .data_out (operation_mode_reg)
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
        .last_word(last_valid_input_word),
        .counter(input_size_counter)
        // The block_size input doesnt really matter here.
        // That is, since we need to account for padding,
        // last_block is driven by the padding generator.
    );

    // Padding Generator
    // NOTE doing this in a parametric way possibly makes it more confusing
    assign remaining_valid_bytes = input_size_counter[(w_bit_width-1):3];
    // NOTE: hacky way of subtracting 1 from odd number, but it should simplify synthesis
    assign last_word_in_block = (input_buffer_counter == {max_buffer_depth[4:1], 1'b0});
    padding_generator padding_gen (
        .clk (clk),
        .rst (rst),
        .data_in (data_in),
        .remaining_valid_bytes(remaining_valid_bytes),
        .padding_enable(padding_enable),
        .last_word_in_block(last_word_in_block),
        .padding_reset(padding_reset),
        .last_block(last_input_block),
        .data_out(padded_data)
    );

    // Counter for input buffer: corresponds to how many positions are filled
    // TODO: Currently, if this counts to N, there are N+1 states, which might not be desirable
    countern #(
        .WIDTH(5)
    ) input_counter (
        .clk  (clk),
        .rst (rst),
        .en (load_enable),
        .load_max (control_regs_enable),
        .max_count (max_buffer_depth),
        .count_start(input_buffer_empty),
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
        .data_out (input_buffer_out)
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
    // Kind of a hack: enable passthrough so we can get the
    // correct value of operation mode
    assign operation_mode = control_regs_enable ? data_in[62:61] : operation_mode_reg;
    // Input transformations
    assign padded_data_le = EndianSwitcher#(w)::switch(padded_data);


endmodule