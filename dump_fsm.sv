module load_fsm (
    input  logic clk,
    input  logic rst,
    input  logic ready_i,
    input  logic output_block_pending,

    output logic output_counter_load,
    output logic output_counter_rst,



    input  logic valid_i,
    input  logic input_buffer_empty,
    input  logic input_buffer_full,
    input  logic last_input_block,

    output logic ready_o,
    output logic load_enable,
    output logic control_regs_enable,
    output logic copy_control_regs_en,
    output logic input_buffer_ready_wr,  // Handshaking signal
    output logic last_block_in_buffer_wr // Handshaking signal, TODO: find better name
);

    logic input_buffer_loadable;

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


    // TODO: this will probably include also some data from the second stage,
    // like if the buffer has been used or not
    assign input_buffer_loadable = input_buffer_empty;
    assign last_block_in_buffer_wr = last_input_block;


    // Next state logic
    always_comb begin
        output_counter_load                = 0;
        output_counter_rst            = 0;
        input_buffer_ready_wr  = 0;
        control_regs_enable    = 0;
        copy_control_regs_en   = 0;

        unique case (current_state)
            // Initial state for resetting
            IDLE: begin
                if (output_block_pending) begin
                    next_state = WRITING;
                end
                else begin
                    output_counter_rst = 1;
                    next_state = IDLE;
                end
            end

            default: next_state = RESET;
        endcase
    end

endmodule
