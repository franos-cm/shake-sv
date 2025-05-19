module permute_fsm (
    input  logic clk,
    input  logic rst,
    input  logic input_buffer_ready,
    input  logic last_block_in_input_buffer,
    input  logic round_done,
    input  logic output_buffer_ready,
    input  logic last_output_block,

    output logic copy_control_regs_en,  // TODO: do I need to copy input size? Probably not, but double check it.
    output logic absorb_enable,
    output logic round_en,
    output logic output_buffer_we,         // NOTE: this means a previous stage of the pipeline is driving a next stage
    output logic input_buffer_ready_clr,   // Handshaking signal
    output logic last_block_in_buffer_clr  // Handshaking signal
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
            current_state <= RESTART;
        else
            current_state <= next_state;
    end


    // Next state logic
    always_comb begin
        ready_o                  = 0;
        input_buffer_we          = 0;
        input_buffer_ready_clr   = 0;
        last_block_in_buffer_clr = 0;
        copy_control_regs_en     = 0; // In a way, signals that a new hash has started...

        unique case (current_state)
            // Initial state for resetting
            RESET: begin
                next_state = WAIT_FIRST_ABSORB;
                input_buffer_ready_clr = 1;
                last_block_in_buffer_clr = 1;
                // TODO: drive a universal reset here
            end

            // Wait until first pipeline stage stays buffer is ready for the first time
            WAIT_FIRST_ABSORB: begin
                if (!input_buffer_ready) begin
                    next_state = WAIT_FIRST_ABSORB;
                end
                else begin
                    absorb_enable = 1;
                    round_en = 1;
                    copy_control_regs_en = 1;
                    input_buffer_ready_clr = 1;
                    next_state = last_block_in_input_buffer ? ABSORB_LAST : ABSORB;
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
                    absorb_enable = 1;
                    round_en = 1;
                    input_buffer_ready_clr = 1;
                    next_state = last_block_in_input_buffer ? ABSORB_LAST : ABSORB;
                end
            end


            // Absorb blocks until either there is no block available, or we reach the last one
            ABSORB: begin
                // Either round is not done, or it is done and we can go straight to absorbing the next (non last) block
                if ((!round_done) || (round_done && input_buffer_ready && !last_block_in_input_buffer)) begin
                    next_state = ABSORB;
                    absorb_enable = round_done;
                    round_en = 1; // TODO: this looks weird, revise it
                end
                // Or, if round is done, and the last block is waiting to be absorbed, we change states
                else if (round_done && input_buffer_ready && last_block_in_input_buffer) begin
                    next_state = ABSORB_LAST;
                    absorb_enable = 1;
                    round_en = 1; // We do this so the round_counter resets
                end
                // Otherwise, round is done and the next block is not ready for absorption, and we go back to waiting
                else begin
                    next_state = WAIT_NEXT_ABSORB;
                    round_en = 1; // We do this so the round_counter resets
                end
            end

            // Absorbs last block
            ABSORB_LAST: begin
                round_en = 1;
                last_block_in_buffer_clr = 1;
                next_state = round_done ? DUMP : ABSORB_LAST;
            end

            // If output buffer is ready, dump digest on it
            DUMP: begin
                output_buffer_we = output_buffer_ready;

                // This will only happen in the first DUMP cycle, where out buffer is ready by definition,
                // or in subsequent DUMP cycles, where WAIT_DUMP guarantees out buffer is ready.
                // As such, we dont need to check for (is_ready)
                if (!last_output_block) begin
                    next_state = SQUEEZE;
                end
                else begin
                    // Trying to get rid of that last state by cycling in DUMP
                    // TODO: more complex transitions if last_output_block, straight to ABSORB or ABSORB_LAST
                    next_state = output_buffer_ready ? WAIT_FIRST_ABSORB : DUMP;
                end
            end

            // Squeeze another block
            SQUEEZE: begin
                round_en = 1;
                next_state = round_done ? WAIT_DUMP : SQUEEZE;
            end

            // Squeeze another block
            WAIT_DUMP: begin
                next_state = output_buffer_ready ? DUMP : WAIT_DUMP;
            end

            default: next_state = RESET;
        endcase
    end

endmodule
