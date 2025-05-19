import keccak_pkg::*;


module load_datapath (
    input  logic clk,
    input  logic rst,
    input  logic load_enable,
    input  logic control_regs_enable,
    input  logic[w-1:0] data_in,

    output logic input_buffer_empty,
    output logic input_buffer_full,
    output logic last_input_block,
    output logic[RATE_SHAKE128-1:0] input_buffer_out,
    output logic[31:0] output_size,
    output logic[1:0] operation_mode
);
    // ---------- Internal signals declaration ----------
    //
    logic last_input_word;
    logic [1:0]  operation_mode_reg;
    logic [10:0] block_size;
    logic [4:0]  max_buffer_depth;


    // ------------------- Components -------------------
    //
    // Operation mode reg, to decide current block size
    regn #(
        .WIDTH(2)
    ) operation_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (control_regs_enable),
        .data_in (data_in[62:61]), // We only need the middle bits, those are the ones that change
        .data_out (operation_mode_reg)
    );

    // Output size reg, to transmit to next pipeline stage
    regn #(
        .WIDTH(32)
    ) operation_mode_reg (
        .clk  (clk),
        .rst (rst),
        .en (control_regs_enable),
        .data_in ('0 & data_in[59:32]), // TODO: not sure this works
        .data_out (output_size)
    );

    // Input size counter, to count down in this stage
    size_counter #(
        .WIDTH(32),
        .w(w)
    ) input_size_left (
        .clk (clk),
        .rst (rst),
        .en_write(control_regs_enable),
        .en_count(load_enable),
        .block_size(block_size),
        .step_size(0' & logic'(w)), // TODO: can I do this?
        .data_in(data_in[31:0]),
        .last_word(last_input_word),
        .last_block(last_input_block)
    );

    // Counter for input buffer
    countern #(
        .WIDTH(5)
    ) input_counter (
        .clk  (clk),
        .rst (rst),
        .en (load_enable),
        .load_max (control_regs_enable),
        .max_count (max_buffer_depth),
        .count_start(input_buffer_empty),
        .count_end (input_buffer_full)
    );

    // TODO: add padding to before input buffer
    sipo_buffer #(
        .WIDTH(w),
        .DEPTH(RATE_SHAKE128/w) // TODO: does this division work?
    ) input_buffer(
        .clk (clk),
        .rst (rst),
        .en (load_enable),
        .data_in (data_in),
        .data_out (input_buffer_out)
    );


    // ------------ Combinatorial assignments -----------
    //
    // Decide block size based on current operation mode
    always_comb begin
        unique case (operation_mode)
            SHAKE256_MODE_VEC: begin
                block_size = RATE_SHAKE256_VEC;
                max_buffer_depth = 5'd17; // TODO: Maybe 18?
            end
            SHAKE128_MODE_VEC: begin
                block_size = RATE_SHAKE128_VEC;
                max_buffer_depth = 5'd21;
            end
            default: begin
                block_size = '0;
                max_buffer_depth = 5'd21;
            end
        endcase
    end
    // Kind of a hack: enable passthrough so we can get the
    // correct value of operation mode
    assign operation_mode = control_regs_enable ? data_in[62:61] : operation_mode_reg;


endmodule