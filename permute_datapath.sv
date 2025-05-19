import keccak_pkg::*;


module permute_datapath (
    // Master signals
    input  logic clk,
    input  logic rst,
    // Signals from FSM
    input  logic copy_control_regs_en;
    input  logic absorb_enable,
    input  logic round_en,
    // Signals from previous pipeline stage
    input  logic[RATE_SHAKE128-1:0] rate_input,
    input  logic[31:0] output_size_in,
    input  logic[1:0] operation_mode_in,

    
    // Signals for next pipeline stage
    output logic round_done,
    output logic last_output_block,
    output logic[RATE_SHAKE128-1:0] rate_output
    
);
    // ---------- Internal signals declaration ----------
    //
    logic[1:0] operation_mode;
    logic[1:0] operation_mode_reg;
    logic[10:0] block_size; 

    logic[10:0] last_output_block;
    logic[10:0] last_output_block;

    logic[state_width-1:0] state_reg_in;
    logic[state_width-1:0] state_reg_out;
    logic[$clog2(24)-1:0] round_num;
    logic[state_width-1:0] round_in;
    logic[state_width-1:0] xor_mask;
    logic[w-1:0] round_constant;



    // ------------------- Components -------------------
    //
    // Reg for current mode, coming from previous stage
    regn #(
        .N(2)
    ) state_reg (
        .clk  (clk),
        .rst (rst),
        .en (copy_control_regs_en),
        .data_in (operation_mode_in),
        .data_out (operation_mode_reg)
    );

    // Output size counter, coming from previous stage
    size_counter #(
        .WIDTH(32),
        .w(w)
    ) output_size_left (
        .clk (clk),
        .rst (rst),
        .en_write(copy_control_regs_en),
        .en_count(load_enable), // TODO: Change these
        .block_size(block_size),
        .step_size(32'block_size), // TODO: is this conversion fine?
        .data_in(output_size_in),
        .last_block(last_output_block)
    );


    // Round number counter
    countern #(
        .WIDTH(5) 
    ) round_counter (
        .clk  (clk),
        .rst (rst),  // TODO: Maybe get a more specific reset?
        .en (round_en),
        .load_max (0),
        .max_count(5'd24),    // TODO: Maybe 25?
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
        .N(state_width)
    ) state_reg (
        .clk  (clk),
        .rst (rst),
        .en (round_en),
        .data_in (state_reg_in),
        .data_out (state_reg_out)
    );

    // Keccak round
    keccak_round round(
        .round_in(round_in),
        .round_constant_signal(round_constant),
        .round_out(state_reg_in)
    );

    // ------------ Combinatorial assignments -----------
    //
    // Enables absorption of input by the keccak round
    assign xor_mask = (
        absorb_enable
        ? (operation_mode == SHAKE256_MODE_VEC
            ? rate_input[RATE_SHAKE256-1 : 0] & '0
            : rate_input[RATE_SHAKE128-1 : 0] & '0)
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

    // Output assignment
    assign rate_output = state_reg_out[RATE_SHAKE128-1 : 0];

endmodule