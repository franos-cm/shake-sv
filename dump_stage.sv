import keccak_pkg::*;

module dump_stage (
    // External inputs
    input  logic clk,
    input  logic rst,

    // Inputs from previous stage
    input logic [RATE_SHAKE128-1:0] output_buffer_in,
    input logic [1:0] operation_mode_in,
    input logic output_buffer_we,

    // Handshaking
    input logic copy_op_mode_reg_en,

    // External output
    output logic[w-1:0] data_out
    output logic valid_o;
);
    // ---------- Internal signals declaration ----------
    //
    logic output_buffer_shift_enable;
    logic output_buffer_empty;
    logic operation_mode_reg;
    logic [1:0] operation_mode;
    logic [4:0] max_buffer_depth;



    // ------------------- Components -------------------
    //
    // Reg for current mode, coming from previous stage
    regn #(
        .N(2)
    ) state_reg (
        .clk  (clk),
        .rst (rst),
        .en (copy_op_mode_reg_en),
        .data_in (operation_mode_in),
        .data_out (operation_mode_reg)
    );


    countern #(
        .WIDTH(5)
    ) output_counter (
        .clk  (clk),
        .rst (rst),
        .en (output_counter_enable),
        .count_up (0),
        .count_start (output_buffer_empty)
    );

    // Counter for input buffer
    countern #(
        .WIDTH(5)
    ) input_counter (
        .clk  (clk),
        .rst (rst),
        .en (output_counter_enable),
        .load_max (control_regs_enable),
        .max_count (max_buffer_depth),
        .count_start(input_buffer_empty),
        .count_end(input_buffer_full)
    );

    piso_buffer #(
        .WIDTH(w),
        .DEPTH(RATE_SHAKE128/w)
    ) output_buffer(
        .clk (clk),
        .rst (rst),
        .write_enable (output_buffer_we),
        .write_enable (output_buffer_shift_enable),
        .data_in (output_buffer_in),
        .data_out (data_out)
    );

    // ------------ Combinatorial assignments -----------
    //
    always_comb begin
        unique case (operation_mode)
            SHAKE256_MODE_VEC: max_buffer_depth = 5'd17;
            SHAKE128_MODE_VEC: max_buffer_depth = 5'd21;
            default: max_buffer_depth = 5'd21;
        endcase
    end
    // Kind of a hack: enable passthrough so we can get the
    // correct value of operation mode in the first absorb
    assign operation_mode = copy_control_regs_en ? operation_mode_in : operation_mode_reg;

    assign output_buffer_shift_enable = (!output_buffer_empty) && ready_in;
    assign valid_o = !output_buffer_empty;

endmodule