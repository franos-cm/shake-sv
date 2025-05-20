module load_fsm (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic input_buffer_empty,
    input  logic input_buffer_full,
    input  logic last_input_block,

    output logic ready_out,
    output logic load_enable,
    output logic control_regs_enable,
    output logic padding_reset,
    output logic input_buffer_ready_wr, // Handshaking signal
    output logic last_block_in_buffer_wr // Handshaking signal, TODO: find better name
);

    // Define states using enum
    typedef enum logic [5:0] {
        RESET,
        WAIT_HEADER,
        WAIT_LOAD,
        LOAD
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= RESET;
        else
            current_state <= next_state;
    end


    // TODO: this will probably include also some data from the second stage,
    // like if the buffer has been used or not
    assign last_block_in_buffer_wr = last_input_block;


    // Next state logic
    always_comb begin
        ready_out              = 0;
        load_enable            = 0;
        input_buffer_ready_wr  = 0;
        control_regs_enable    = 0;
        padding_reset          = 0;

        unique case (current_state)
            // Initial state for resetting
            RESET: begin
                next_state = WAIT_HEADER;
                // TODO: drive a universal reset here
            end

            // Waits for initial input (valid_in = 1), and when that happens,
            // registers input_length, output_length, and mode, in first stage regs
            WAIT_HEADER: begin
                if (valid_in) begin
                    next_state = WAIT_LOAD;
                    control_regs_enable = 1;
                end else begin
                    next_state = WAIT_HEADER;
                end
            end

            // Waits so sipo buffer is available to be loaded
            WAIT_LOAD: begin
                next_state = input_buffer_empty ? LOAD : WAIT_LOAD;
            end

            //  When it is available, load sipo according to valid_in
            LOAD: begin
                if (!input_buffer_full) begin
                    if (valid_in) begin
                        load_enable = 1;
                        ready_out = 1;
                    end
                    next_state = LOAD;
                end
                else begin
                    input_buffer_ready_wr = 1; // Signal to next pipeline state that buffer is ready
                    next_state = last_input_block ? WAIT_HEADER : WAIT_LOAD;
                    padding_reset = last_input_block;
                end
            end

            default: next_state = RESET;
        endcase
    end

endmodule
