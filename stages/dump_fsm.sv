`timescale 1ns / 1ps

module dump_fsm (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic ready_in,

    // Status signals
    input  logic output_buffer_empty,

    // Control signals
    output logic output_counter_load,
    output logic output_counter_rst,
    output logic output_buffer_shift_en,
    output logic valid_bytes_enable,
    output logic valid_bytes_reset,
    output logic intermediate_buffer_we,
    output logic output_buffer_we_out,
    output logic last_output_block_out,

    // Pipeline handshaking
    input  logic output_buffer_we_in,
    input  logic last_output_block_in,
    output logic last_output_block_clr,
    output logic output_buffer_available_wr,

    // External outputs
    output logic valid_out
);

    // FSM states
    typedef enum logic [5:0] {
        IDLE,
        PRE_WRITE,
        WRITING
    } state_t;
    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end


    // -------------- Mealy Finite State Machine --------------
    always_comb begin
        output_counter_load        = 0;
        output_buffer_shift_en     = 0;
        output_buffer_available_wr = 0;
        valid_out                  = 0;
        valid_bytes_enable         = 0;
        output_buffer_we_out       = 0;
        intermediate_buffer_we     = 0;
        last_output_block_clr      = rst;
        output_counter_rst         = rst;
        valid_bytes_reset          = rst;

        unique case (current_state)
            // Initial state
            IDLE: begin
                if (output_buffer_we_in) begin
                    output_counter_load = 1;
                    valid_bytes_enable = last_output_block_in;
                    valid_bytes_reset = !last_output_block_in;
                    intermediate_buffer_we = 1;
                    next_state = PRE_WRITE;
                end
                else begin
                    output_buffer_available_wr = 1;
                    output_counter_rst = 1;
                    next_state = IDLE;
                end
            end

            PRE_WRITE: begin
                output_buffer_we_out = 1;
                next_state = WRITING;
            end

            WRITING: begin
                // NOTE: in theory, probably we could do valid_out = 1 here,
                //       but this more closely mirrors the original module.
                valid_out = ready_in;

                if (output_buffer_empty && ready_in) begin
                    output_buffer_available_wr = 1;
                    last_output_block_clr = 1;
                    output_buffer_shift_en = 1; // NOTE: unecessary, but mirrors original
                    next_state = IDLE;
                end
                else begin
                    output_buffer_shift_en = ready_in;
                    next_state = WRITING;
                end
            end

            default: next_state = IDLE;
        endcase
    end


    // -------------- Other comb assignments --------------
    // Passthrough
    assign last_output_block_out = last_output_block_in;

endmodule
