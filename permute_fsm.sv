module permute_fsm (
    input  logic clk,
    input  logic rst,
    input  logic input_buffer_ready,
    input  logic last_block_in_input_buffer,
    input  logic round_done,
    input  logic round_start,
    input  logic output_buffer_available,
    input  logic last_output_block,

    output logic copy_control_regs_en,
    output logic absorb_enable,
    output logic round_en,
    output logic round_count_load,
    output logic output_buffer_we,
    output logic state_reset,
    output logic input_buffer_ready_clr,   // Handshaking signal
    output logic last_block_in_buffer_clr, // Handshaking signal
    output logic last_output_block_wr      // Handshaking signal
);

    // Define states using enum
    typedef enum logic [5:0] {
        RESET,
        WAIT_FIRST_ABSORB,
        ABSORB,
        WAIT_NEXT_ABSORB,
        ABSORB_LAST,
        DUMP,
        SQUEEZE,
        WAIT_DUMP
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

    assign last_output_block_wr  = last_output_block;

    // Next state logic
    always_comb begin
        absorb_enable            = 0;
        round_en                 = 0;
        output_buffer_we         = 0;
        input_buffer_ready_clr   = 0;
        last_block_in_buffer_clr = 0;
        copy_control_regs_en     = 0;
        round_count_load         = 0;
        state_reset              = 0;

        unique case (current_state)
            // Initial state for resetting
            RESET: begin
                next_state = WAIT_FIRST_ABSORB;
                round_count_load = 1;
                // TODO: drive a universal reset here
                state_reset = 1;
            end

            // Wait until first pipeline stage stays buffer is ready for the first time
            WAIT_FIRST_ABSORB: begin
                if (!input_buffer_ready) begin
                    next_state = WAIT_FIRST_ABSORB;
                end
                else begin
                    copy_control_regs_en = 1;
                    absorb_enable = 1;
                    round_en = 1;
                    input_buffer_ready_clr = 1;
                    next_state = last_block_in_input_buffer ? ABSORB_LAST : ABSORB;
                    last_block_in_buffer_clr = last_block_in_input_buffer;
                end
            end

            // Wait until first pipeline stage stays buffer is ready again
            // NOTE: the only difference between this and WAIT_FIRST_ABSORB,
            //       is that we dont drive copy_control_regs_en=1.
            WAIT_NEXT_ABSORB: begin
                if (!input_buffer_ready) begin
                    next_state = WAIT_NEXT_ABSORB;
                end
                else begin
                    next_state = last_block_in_input_buffer ? ABSORB_LAST : ABSORB;
                    absorb_enable = 1;
                    round_en = 1;
                    input_buffer_ready_clr = 1;
                    last_block_in_buffer_clr = last_block_in_input_buffer;
                end
            end


            // Absorb blocks until either there is no block available, or we reach the last one
            ABSORB: begin
                // Either round is not done, or it is done and we can go straight to absorbing the next (non last) block
                if ((!round_done) || (round_done && input_buffer_ready && !last_block_in_input_buffer)) begin
                    next_state = ABSORB;
                    round_en = 1;
                    // NOTE: this round_start condition is necessary so we delay one cycle for XORing the new block
                    // But since the input_buffer_ready handshaking takes an extra clock, we can clear it earlier
                    absorb_enable = round_start;
                    input_buffer_ready_clr = round_done;
                end

                // Or, it is done and we can go straight to absorbing the next (non last) block
                // else if (round_done && input_buffer_ready && !last_block_in_input_buffer) begin
                //     next_state = ABSORB;
                //     round_en = 1;
                // end

                // Or, if round is done, and the last block is waiting to be absorbed, we change states
                else if (round_done && input_buffer_ready && last_block_in_input_buffer) begin
                    next_state = ABSORB_LAST;
                    last_block_in_buffer_clr = 1;
                    input_buffer_ready_clr   = 1;
                    round_en = 1; // NOTE: we do this so the counter resets
                end
                // Otherwise, round is done and the next block is not ready for absorption, and we go back to waiting
                else begin
                    next_state = WAIT_NEXT_ABSORB;
                    round_en = 1; // NOTE: we do this so the counter resets
                end
            end

            // Absorbs last block
            ABSORB_LAST: begin
                next_state = round_done ? DUMP : ABSORB_LAST;
                round_en = 1;
                // NOTE: this round_start condition is necessary so we delay one cycle for XORing the new block
                absorb_enable = round_start;
            end

            // If output buffer is ready, dump digest on it
            DUMP: begin
                output_buffer_we = output_buffer_available;

                // This will only happen in the first DUMP cycle, where out buffer is ready by definition,
                // or in subsequent DUMP cycles, where WAIT_DUMP guarantees out buffer is ready.
                // As such, we dont need to check for (output_buffer_available)
                if (!last_output_block) begin
                    next_state = SQUEEZE;
                end
                else begin
                    // Trying to get rid of that last state by cycling in DUMP
                    // TODO: more complex transitions if last_output_block, straight to ABSORB or ABSORB_LAST
                    next_state = output_buffer_available ? WAIT_FIRST_ABSORB : DUMP;
                    state_reset = output_buffer_available;
                    copy_control_regs_en = output_buffer_available;
                end
            end

            // Squeeze another block
            SQUEEZE: begin
                round_en = 1;
                next_state = round_done ? WAIT_DUMP : SQUEEZE;
            end

            // Squeeze another block
            WAIT_DUMP: begin
                next_state = output_buffer_available ? DUMP : WAIT_DUMP;
            end

            default: next_state = RESET;
        endcase
    end

endmodule
