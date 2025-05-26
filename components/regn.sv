module regn #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1:0] INIT = '0
) (
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
    logic [WIDTH-1:0] buffer = 0;

    always_ff @(posedge clk) begin
        if (rst)
            buffer <= INIT;
        else if (en)
            buffer <= data_in;
    end
    
    assign data_out = buffer;

endmodule
