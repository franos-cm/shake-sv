module load_fsm (
    // External inputs
    input  logic clk,
    input  logic rst,
    input  logic valid_in,

    // Status signals
    input  logic input_buffer_full,
    input  logic first_incomplete_input_word,
    input  logic last_input_block,
    input  logic input_size_reached,

    // Control signals
    output logic control_regs_enable,
    output logic load_enable,
    output logic input_counter_en,
    output logic input_counter_load,
    output logic padding_reset,
    output logic padding_enable,

    // Second stage pipeline handshaking
    input  logic input_buffer_ready,
    output logic input_buffer_ready_wr,
    output logic last_block_in_buffer_wr,

    // External outputs
    output logic ready_out
);

    // FSM states
    typedef enum logic [5:0] {
        RESET,
        WAIT_HEADER,
        WAIT_LOAD,
        LOAD,
        WAIT_BUFFER_EMPTY
    } state_t;
    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= RESET;
        else
            current_state <= next_state;
    end


    // -------------- Mealy Finite State Machine --------------
    always_comb begin
        ready_out              = 0;
        load_enable            = 0;
        input_buffer_ready_wr  = 0;
        control_regs_enable    = 0;
        padding_enable         = 0;
        padding_reset          = 0;
        input_counter_en       = 0;
        input_counter_load     = 0;

        unique case (current_state)
            // Initial state for resetting
            RESET: begin
                next_state = WAIT_HEADER;
                padding_reset = 1;
            end

            // Waits for initial input (valid_in = 1), and when that happens,
            // registers input_length, output_length, and mode, in first stage regs
            WAIT_HEADER: begin
                if (valid_in) begin
                    next_state = WAIT_LOAD;
                    control_regs_enable = 1;
                    ready_out = 1;
                end else begin
                    next_state = WAIT_HEADER;
                end
            end

            // Waits so sipo buffer is available to be loaded
            WAIT_LOAD: begin
                next_state = input_buffer_ready ? WAIT_LOAD : LOAD;
                input_counter_load = 1;
            end

            //  When it is available, load sipo according to valid_in
            LOAD: begin
                padding_enable = first_incomplete_input_word;
                if (!input_buffer_full) begin
                    load_enable = valid_in || padding_enable;
                    input_counter_en = load_enable;
                    ready_out = valid_in && !input_size_reached;
                    next_state = LOAD;
                end
                else begin
                    input_buffer_ready_wr = 1; // Signal to next pipeline state that buffer is ready
                    input_counter_en = 1;      // NOTE: we do this to reset the input counter
                    padding_reset = last_input_block;
                    next_state = last_input_block ? WAIT_BUFFER_EMPTY : WAIT_LOAD;
                end
            end

            WAIT_BUFFER_EMPTY: begin
                next_state = input_buffer_ready ? WAIT_BUFFER_EMPTY : WAIT_HEADER;
            end

            default: next_state = RESET;
        endcase
    end


    // -------------- Other comb assignments --------------
    // Passthrough
    assign last_block_in_buffer_wr = last_input_block;


endmodule
