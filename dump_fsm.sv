module dump_fsm (
    input  logic clk,
    input  logic rst,
    input  logic ready_in,
    input  logic output_buffer_we,
    input  logic output_size_reached,
    input  logic output_buffer_empty,

    // Control output signals
    output logic output_counter_load,
    output logic output_counter_rst,
    output logic output_buffer_shift_en,

    // External outputs
    output logic valid_out,

    // Handshaking
    output logic output_buffer_available_wr
);

    logic data_still_in_buffer;

    // Define states using enum
    typedef enum logic [5:0] {
        IDLE,
        WRITING
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    assign data_still_in_buffer = (!output_buffer_empty) && (!output_size_reached);

    // Next state logic
    always_comb begin
        output_counter_load        = 0;
        output_counter_rst         = 0;
        output_buffer_shift_en     = 0;
        output_buffer_available_wr = 0;
        valid_out                  = 0;

        unique case (current_state)
            // Initial state
            IDLE: begin
                if (output_buffer_we) begin
                    output_counter_load = 1;
                    next_state = WRITING;
                end
                else begin
                    output_buffer_available_wr = 1;
                    output_counter_rst = 1;
                    next_state = IDLE;
                end
            end

            // LEFT HERE: add a delay state to load counter with correct value
            //            or... use last_word in some way
            //            second one probably better, since it
            // is more performative. Will require more specific counter though

            WRITING: begin
                if (data_still_in_buffer) begin
                    valid_out = 1;
                    output_buffer_shift_en = ready_in;
                    next_state = WRITING;
                end
                else begin
                    output_buffer_available_wr = 1;
                    output_counter_rst = 1; // TODO: possibly unnecessary
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
