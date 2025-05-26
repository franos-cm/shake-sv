module piso_buffer #(
    parameter int WIDTH,
    parameter int DEPTH
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     write_enable,
    input  logic                     shift_enable,
    input  logic[(DEPTH*WIDTH)-1:0]  data_in,
    output logic[WIDTH-1:0]          data_out
);
    logic [WIDTH-1:0] buffer_data [DEPTH-1:0];

    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            // reset
            for (int i = 0; i < DEPTH; i++)
                buffer_data[i] <= '0;
        end
        else if (write_enable) begin
            for (int i = 0; i < DEPTH; i++)
                buffer_data[i] <= data_in[(DEPTH-i)*(WIDTH)-1 -: WIDTH];
        end
        else if (shift_enable) begin
                // shift
                for (int i = DEPTH - 1; i > 0; i--)
                    buffer_data[i] <= buffer_data[i - 1];
                buffer_data[0] <= '0;
        end

    assign data_out = buffer_data[DEPTH - 1];
endmodule