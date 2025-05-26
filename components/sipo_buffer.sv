module sipo_buffer #(
    parameter int WIDTH,
    parameter int DEPTH
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          en,
    input  logic[WIDTH-1:0]           data_in,
    output logic[(DEPTH*WIDTH)-1:0]   data_out
);
    logic [WIDTH-1:0] buffer_data [DEPTH-1:0];

    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            // reset
            for (int i = 0; i < DEPTH; i++)
                buffer_data[i] <= '0;
        end
        else if (en) begin
            // shift
            for (int i = 0; i < DEPTH - 1; i++)
                buffer_data[i] <= buffer_data[i + 1];
            buffer_data[DEPTH - 1] <= data_in;
        end

    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            data_out[(i+1)*WIDTH-1 -: WIDTH] = buffer_data[DEPTH-1-i];
        end
    end
endmodule