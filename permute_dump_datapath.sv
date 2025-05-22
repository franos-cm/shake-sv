import keccak_pkg::*;


module permute_dump_datapath (
    // Master signals
    input  logic clk,
    input  logic rst,

    // Inputs from previous pipeline stage
    input  logic[RATE_SHAKE128-1:0] rate_input,
    input  logic[31:0] output_size_in,
    input  logic[1:0] operation_mode_in,

    // Control inputs
    input  logic copy_control_regs_en,
    input  logic absorb_enable,
    input  logic round_en,
    input  logic round_count_load,

    input  logic output_buffer_we,
    input  logic output_buffer_shift_en,
    input  logic output_counter_load,
    input  logic output_counter_rst,

    // Control outputs
    output logic output_buffer_empty,
    output logic round_done,
    output logic last_output_block,
    output logic output_size_reached,

    // External outputs
    output logic[w-1:0] data_out
    
);
    // ---------- Internal signals declaration ----------
    //
    logic[1:0] operation_mode;
    logic[1:0] operation_mode_reg;
    logic[10:0] block_size;

    logic[STATE_WIDTH-1:0] state_reg_in;
    logic[STATE_WIDTH-1:0] state_reg_out;
    logic[$clog2(24)-1:0] round_num;
    logic[STATE_WIDTH-1:0] round_in;
    logic[STATE_WIDTH-1:0] xor_mask;
    logic[w-1:0] round_constant;

    logic[RATE_SHAKE128-1:0] rate_output;
    logic[31:0] output_size_counter;
    logic[31:0] size_step;
    logic [4:0] max_buffer_depth;
    logic[w_byte_width-1:0] remaining_valid_bytes;
    logic output_size_count_en;



    // -------------- Permute Components ----------------
    //
    // Reg for current mode, coming from previous stage
    regn #(
        .WIDTH(2)
    ) op_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (copy_control_regs_en),
        .data_in (operation_mode_in),
        .data_out (operation_mode_reg)
    );


    // Round number counter
    countern #(
        .WIDTH(5) 
    ) round_counter (
        .clk  (clk),
        .rst (rst),  // TODO: Maybe get a more specific reset?
        .en (round_en),
        .load_max (round_count_load),
        .max_count(5'd23),
        .counter(round_num),
        .count_end(round_done)
    );

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
        .rst (rst),
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

    // ---------------- Dump Components ------------------
    //
    // Output size counter, coming from previous stage
    // TODO: check if this works
    assign output_size_count_en = (output_buffer_we && !last_output_block) || output_buffer_shift_en;
    size_counter #(
        .WIDTH(32),
        .w(w)
    ) output_size_left (
        .clk (clk),
        .rst (rst),
        .en_write(copy_control_regs_en),
        .en_count(output_size_count_en),
        .block_size(block_size),
        .step_size(size_step),
        .data_in(output_size_in),
        .last_block(last_output_block),
        .last_word(last_output_word),
        .counter_end(output_size_reached),
        .counter(output_size_counter)
    );

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
        .data_in (rate_output),
        .data_out (data_out)
    );

    // ------- Permute Combinatorial assignments ---------
    //
    // Enables absorption of input by the keccak round
    assign xor_mask = (
        absorb_enable
        ? (operation_mode == SHAKE256_MODE_VEC
            ? {rate_input[RATE_SHAKE256-1 : 0], {CAP_SHAKE256{1'b0}}}
            : {rate_input[RATE_SHAKE128-1 : 0], {CAP_SHAKE128{1'b0}}})
        : '0
    );
    assign round_in = state_reg_out ^ xor_mask;
    
    // Decide block size based on current operation mode
    always_comb begin
        unique case (operation_mode)
            SHAKE256_MODE_VEC : block_size = RATE_SHAKE256_VEC;
            SHAKE128_MODE_VEC : block_size = RATE_SHAKE128_VEC;
            default: block_size = '0;
        endcase
    end

    // Kind of a hack: enable passthrough so we can get the
    // correct value of operation mode in the first absorb
    assign operation_mode = copy_control_regs_en ? operation_mode_in : operation_mode_reg;
    
    // Permute output assignment
    assign rate_output = EndianSwitcher#(RATE_SHAKE128)::switch(state_reg_out[STATE_WIDTH-1 -: RATE_SHAKE128]);


    // --------- Dump Combinatorial assignments -----------
    //
    always_comb begin
        unique case (operation_mode)
            SHAKE256_MODE_VEC: max_buffer_depth = 5'd17;
            SHAKE128_MODE_VEC: max_buffer_depth = 5'd21;
            default: max_buffer_depth = 5'd21;
        endcase
    end

    assign size_step = last_output_block ? w : {21'b0, block_size}; // TODO: does this assignment work?
    // Use this for masking output?
    assign remaining_valid_bytes = output_size_counter[(w_bit_width-1):3];

endmodule