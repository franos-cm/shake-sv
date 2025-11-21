import keccak_pkg::*;

module tb;
    // Constants
    localparam integer P = 10;
    localparam MAX_TV_SIZE = 2;
    localparam MAX_DIGEST_SIZE = 8 * 1024 * 1024;
    localparam MAX_MESSAGE_SIZE = 8 * 1024 * 1024;

    // Change these if necessary
    localparam string TV_PATH = "/home/franos/projects/shake-sv/tb/kat/";
    localparam string RESULTS_DIR = "/home/franos/projects/shake-sv/tb/results/";
    localparam TV = 1;

    string file_name;
    integer csv_fd;
    logic done = 0;
    logic failed = 0;

    logic clk = 1;
    logic rst;
    logic valid_i,  ready_o;
    logic ready_i, valid_o;
    logic  [w-1:0] data_i;  
    logic [w-1:0] data_o;

    logic [w-1:0] config_words [0 : MAX_TV_SIZE - 1];
    logic [MAX_MESSAGE_SIZE-1:0] messages [0 : MAX_TV_SIZE - 1];
    logic [0:MAX_DIGEST_SIZE-1] digests [0 : MAX_TV_SIZE - 1];
    logic [31:0] input_size;
    logic [31:0] output_size;

    typedef enum logic [3:0] {
        S_INIT, S_EXECUTE, S_STOP
    } state_t;
    state_t state;


    initial begin
        // Read test vectors
        $readmemh({TV_PATH, "config_word.txt"}, config_words);
        $readmemh({TV_PATH, "message.txt"}, messages);
        $readmemh({TV_PATH, "digest.txt"}, digests);

        // Dump to csv
        file_name = "keccak.csv";
        csv_fd = $fopen({RESULTS_DIR, file_name}, "w");
        if (!csv_fd) begin
            $fatal(1, "Failed to open CSV file for writing — does the directory exist?");
        end
        $fwrite(csv_fd, "total_cycles,success\n");
    end

    // Clock definition
    always #(P/2) clk = ~clk;

    // Some constant signals
    assign output_size = {4'b0, config_words[TV][59:32]};
    assign input_size = config_words[TV][31:0];

    // Cycle counter
    longint unsigned cycle_ctr;
    always_ff @(posedge clk) begin
        if (rst)
            cycle_ctr <= 0;
        else if (state != S_STOP)
            cycle_ctr <= cycle_ctr + 1;
    end

    // Input word counter
    longint unsigned input_ctr;
    always_ff @(posedge clk) begin
        if (rst)
            input_ctr <= 0;
        else if ((state == S_EXECUTE) && valid_i && ready_i)
            input_ctr <= input_ctr + 1;
    end

    // Output word counter
    longint unsigned output_ctr;
    always_ff @(posedge clk) begin
        if (rst)
            output_ctr <= 0;
        else if ((state == S_EXECUTE) && valid_o && ready_o)
            output_ctr <= output_ctr + 1;
    end

    // Device under stress
    keccak dut (
        .clk (clk),
        .rst (rst),
        .ready_o (!ready_o),
        .valid_i (!valid_i),
        .ready_i (ready_i),
        .valid_o (valid_o),
        .data_i (data_i),
        .data_o (data_o)
    );

    initial begin
        $display("Testbench started");
        rst = 1;
        #(2*P);
        rst = 0;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_i             <= 0;
            ready_o             <= 0;
            data_i              <= 0;
            failed              <= 0;
            state               <= S_INIT;
        end

        else begin
            valid_i <= 0;
            ready_o <= 0;
            data_i  <= 0;
        
            unique case (state)
                S_INIT: begin
                    valid_i <= 1;
                    data_i  <= config_words[TV][w-1:0];
                    if (ready_i) begin
                        state  <= S_EXECUTE;
                        data_i <= messages[TV][0 +: w];
                    end
                end

                S_EXECUTE: begin
                    valid_i <= 1;
                    ready_o <= 1;
                    data_i  <= messages[TV][input_ctr*w +: w];

                    if (ready_i) begin
                        if (((input_ctr + 1)*w) >= input_size) begin
                            valid_i <= 0;
                        end
                        data_i <= messages[TV][(input_ctr+1)*w +: w];
                    end

                    if (valid_o && (data_o !== digests[TV][output_ctr*w+:w])) begin
                        $display("Error in word %d: Expected %h, received %h", output_ctr, digests[TV][output_ctr*w+:w], data_o);
                        failed <= 1;
                    end

                    if ((output_ctr*w) >= output_size) begin
                        state  <= S_STOP;
                    end
                end

                S_STOP: begin
                    if (failed) begin
                        $display("FAILURE");
                    end else begin
                        $display("SUCCESS");
                    end

                    $display("Completed in %d clock cycles", cycle_ctr);
                    $fwrite(csv_fd, "%d,%0d\n", cycle_ctr, (!failed));
                    $finish;
                end
            
                default: begin
                    $fatal(1, "Invalid state reached: %0d", state);
                end
            endcase
        end
    end



endmodule