module keccak_fsm (
    input  logic clk,
    input  logic rst,
    input  logic valid_i,
    input  logic ready_i,
    input  logic input_buffer_full,
    input  logic output_buffer_empty,
    input  logic last_input_word,
    input  logic last_output_word,
    input  logic last_output_block,
    input  logic round_done,

    // Put a universal reset here as well
    output logic valid_o,
    output logic ready_o,
    output logic control_regs_enable,
    output logic input_buffer_we,
    output logic output_buffer_we,
    output logic output_buffer_se, // shift enable
    output logic absorb_enable,
    output logic round_count_en,
    output logic round_count_reset,
    output logic state_enable
);

    // Define states using enum
    typedef enum logic [5:0] {
        RESTART,
        START,
        INITIAL_LOAD,
        JUST_EXECUTE,
        EXECUTE_AND_LOAD,
        WAITING_DUMP,
        DUMP
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= RESTART;
        else
            current_state <= next_state;
    end

    
    // Deal with reset state for these assignments, might introduce bugs
    // TODO: both ready_o and input_buffer_we dont seem to take into account
    // the fact that the user might try to start a new transaction without
    // finishing the previous one... Is that possible though?
    // assign ready_o = (
    //     ((current_state == START) && (valid_i))
    //     || (!input_buffer_full)
    // );
    // If the input buffer is not full, and we are not in the start state, get the data
    // assign input_buffer_we = ((current_state != START) && (valid_i) && (!input_buffer_full));


    // If the output buffer is not empty... theres valid data there.
    assign valid_o = !output_buffer_empty;
    // If buffer is not empty and the user has received it... load next word
    assign output_buffer_se = ((!output_buffer_empty) && ready_i);

    // assign output_buffer_we = (round_done && output_buffer_empty && (current_state == JUST_EXECUTE));
    // assign round_count_reset = output_buffer_we; // TODO: If this assignment is correct, we might as well get rid of the signal
    

    // Next state logic
    always_comb begin
        absorb_enable        = 0;
        round_count_en       = 0;
        state_enable         = 0;
        control_regs_enable  = 0;
        output_buffer_we     = 0;
        valid_o              = 0;
        round_count_reset    = 0;

        unique case (current_state)
            // Initial state for resetting
            RESTART: begin
                next_state = START;
                // TODO: Drive a universal reset, instead of individual ones
                round_count_reset = 1;
            end

            // Waits for initial input (valid_i = 1), and when that happens,
            // registers input_length, output_length, and mode, in regs
            START: begin
                if (valid_i) begin
                    next_state = INITIAL_LOAD;
                    control_regs_enable = 1;
                end else begin
                    next_state = START;
                    // NOTE: dont do reset here otherwise output buffer will clear...
                    // Thats why RESTART state is needed.
                end
            end

            
            // Waits for first word to be loaded into buffer, so we can process it
            INITIAL_LOAD: begin
                // Just transition to another state when buffer is full
                if (!input_buffer_full) begin
                    next_state = INITIAL_LOAD;

                // If its the last word, we dont need to load any more data
                // Then we provide the data into Keccak
                // TODO: the signal probably isnt last_input_word
                end else if (input_buffer_full && last_input_word) begin
                    absorb_enable = 1;
                    round_count_en = 1;
                    state_enable = 1;
                    next_state = JUST_EXECUTE;
                end

                // Otherwise, we do
                else if (input_buffer_full && !last_input_word) begin
                    next_state = EXECUTE_AND_LOAD;
                end
            end

            // Execute keccak function 24 times
            // Just execute, as in, dont worry about loading additional data,
            // either because the last input data has already been giving, or because we are squeezing
            JUST_EXECUTE: begin
                if (round_done) begin
                    next_state = last_output_block ? START : JUST_EXECUTE;
                    // next_state = SUPER_DUMP;
                end
                else begin
                    round_count_en = 1;
                    state_enable = 1;
                    next_state = JUST_EXECUTE;
                end
            end

            // TODO: maybe this is better than the other two states, but double check this
            SUPER_DUMP: begin
                // If buffer is empty, lets load it
                if (output_buffer_empty) begin
                    output_buffer_we = 1;
                    round_count_reset = 1;
                    // If this is the last block, return to START
                    // Othewise, run keccak again and squeeze some more
                    next_state = last_output_block ? START : JUST_EXECUTE;
                end
                else begin
                    // TODO: This seems redundant with the last state... but I think it works?
                    // If this is not the last_block... we can still run the keccak rounds
                    if (!round_done && !last_output_block) begin
                        round_count_en = 1;
                        state_enable = 1;
                    end
                    next_state = SUPER_DUMP;
                end
            end










            // WAITING_DUMP: begin
            //     if (output_buffer_empty) begin
            //         output_buffer_we = 1;
            //         // // TODO: not sure if it would be here, or one word later. Also not sure if we go to START or RESTART
            //         // next_state = last_output_word ? START : DUMP;
            //     end
            //     else begin
            //         round_count_reset = 1;
            //         next_state = WAITING_DUMP;
            //     end
            // end

            // DUMP: begin
            //     // LEFT HERE1: put last_output_word and output_buffer_empty condition
            //     if (ready_i) begin
            //         output_buffer_se = 1;
            //     end
            //     if (last_output_block) begin
            //         next_state = START;
            //     end else begin
                    
            //     end
            //     next_state = DUMP;
            // end

            // Placeholder for now
            EXECUTE_AND_LOAD: begin
                next_state = EXECUTE_AND_LOAD;
            end

            default: next_state = RESTART;
        endcase
    end

endmodule
