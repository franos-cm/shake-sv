module countern #(
    parameter int WIDTH = 32
) (
    input  logic  clk,
    input  logic  rst,
    input  logic  en,
    output logic  load_max,
    output logic[WIDTH-1:0] max_count,

    output logic[WIDTH-1:0] counter,
    output logic count_end,
    output logic count_start
);
    // TODO: not satisfied with this load_max and max_count stuff...
    //       makes it probably too complicated
    //       will have to test it
    //       or... make it combinatorial?
    logic [WIDTH-1:0] _counter;
    logic [WIDTH-1:0] _max_count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            _counter <= '0;
            _max_count <= max_count;
        else begin
            if (load_max)
                _max_count <= max_count;
            else if (en)
                _counter <= _counter == max_count ? '0 : _counter + 1;
        end
            
    end

    assign counter = _counter;
    assign count_end = _counter == max_count;
    assign count_start = _counter == '0;
endmodule