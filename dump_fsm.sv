module dump_fsm (
    input  logic clk,
    input  logic rst,
    input  logic ready_in,
    input  logic output_buffer_we,
    input  logic output_size_reached,
    input  logic output_buffer_empty,
    input  logic last_output_block_in,

    // Control output signals
    output logic output_counter_load,
    output logic output_counter_rst,
    output logic output_buffer_shift_en,
    output logic valid_bytes_enable,
    output logic valid_bytes_reset,
    output logic last_output_block,

    // External outputs
    output logic valid_out,

    // Handshaking
    output logic output_buffer_available_wr,
    output logic last_output_block_clr
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

    assign data_still_in_buffer = (!output_buffer_empty);
    assign last_output_block = last_output_block_in;

    // Next state logic
    always_comb begin
        output_counter_load        = 0;
        output_counter_rst         = 0;
        output_buffer_shift_en     = 0;
        output_buffer_available_wr = 0;
        valid_out                  = 0;
        last_output_block_clr      = 0;
        valid_bytes_enable         = 0;
        valid_bytes_reset          = 0;

        unique case (current_state)
            // Initial state
            IDLE: begin
                if (output_buffer_we) begin
                    output_counter_load = 1;
                    valid_bytes_enable = last_output_block_in;
                    valid_bytes_reset = !last_output_block_in;
                    next_state = WRITING;
                end
                else begin
                    output_buffer_available_wr = 1;
                    output_counter_rst = 1;
                    next_state = IDLE;
                end
            end

            WRITING: begin
                if (data_still_in_buffer) begin
                    valid_out = 1;
                    output_buffer_shift_en = ready_in;
                    next_state = WRITING;
                end
                else begin
                    output_buffer_available_wr = 1;
                    last_output_block_clr = 1;
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
