module dump_fsm (
    input  logic clk,
    input  logic rst,
    input  logic ready_in,
    input  logic output_buffer_we_in,
    input  logic output_buffer_empty,

    // Control output signals
    output logic output_buffer_we_out, // NOTE: exists only out of formality
    output logic output_counter_load,  //       and this, out of carefulness
    output logic output_counter_rst,
    output logic output_buffer_shift_en,

    // External outputs
    output logic valid_out,

    // Handshaking
    output logic output_buffer_available_wr
);

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


    // Next state logic
    always_comb begin
        output_counter_load        = 0;
        output_counter_rst         = 0;
        output_buffer_shift_en     = 0;
        output_buffer_available_wr = 0;
        output_buffer_we_out       = 0;
        valid_out                  = 0;

        unique case (current_state)
            // Initial state
            IDLE: begin
                if (output_buffer_we_in) begin
                    output_counter_load = 1;
                    output_buffer_we_out = 1;
                    next_state = WRITING;
                end
                else begin
                    next_state = IDLE;
                end
            end

            WRITING: begin
                if (!output_buffer_empty) begin
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
