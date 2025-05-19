import keccak_pkg::*;

module keccak_f (
    input  keccak_pkg::k_state round_in,
    input  logic [63:0] round_constant_signal,
    output keccak_pkg::k_state round_out
);

    import keccak_pkg::*;

    // Internal signals
    k_state theta_in, theta_out;
    k_state pi_in, pi_out;
    k_state rho_in, rho_out;
    k_state chi_in, chi_out;
    k_state iota_in, iota_out;
    k_plane sum_sheet;

    // Connections between stages
    assign theta_in   = round_in;
    assign rho_in     = theta_out;
    assign pi_in      = rho_out;
    assign chi_in     = pi_out;
    assign iota_in    = chi_out;
    assign round_out  = iota_out;

    // Chi
    genvar x, y, i;
    generate
        for (y = 0; y < 5; y++) begin
            for (x = 0; x < 3; x++) begin
                for (i = 0; i < 64; i++) begin
                    assign chi_out[y][x][i] = chi_in[y][x][i] ^ (~chi_in[y][x+1][i] & chi_in[y][x+2][i]);
                end
            end
            for (i = 0; i < 64; i++) begin
                assign chi_out[y][3][i] = chi_in[y][3][i] ^ (~chi_in[y][4][i] & chi_in[y][0][i]);
                assign chi_out[y][4][i] = chi_in[y][4][i] ^ (~chi_in[y][0][i] & chi_in[y][1][i]);
            end
        end
    endgenerate

    // Theta: compute sum of columns (C[x])
    generate
        for (x = 0; x < 5; x++) begin
            for (i = 0; i < 64; i++) begin
                assign sum_sheet[x][i] = theta_in[0][x][i] ^ theta_in[1][x][i] ^ theta_in[2][x][i] ^ theta_in[3][x][i] ^ theta_in[4][x][i];
            end
        end
    endgenerate

    // Theta: compute D[x] and XOR
    generate
        for (y = 0; y < 5; y++) begin
            for (x = 1; x < 4; x++) begin
                assign theta_out[y][x][0] = theta_in[y][x][0] ^ sum_sheet[x-1][0] ^ sum_sheet[x+1][63];
                for (i = 1; i < 64; i++) begin
                    assign theta_out[y][x][i] = theta_in[y][x][i] ^ sum_sheet[x-1][i] ^ sum_sheet[x+1][i-1];
                end
            end
            assign theta_out[y][0][0] = theta_in[y][0][0] ^ sum_sheet[4][0] ^ sum_sheet[1][63];
            assign theta_out[y][4][0] = theta_in[y][4][0] ^ sum_sheet[3][0] ^ sum_sheet[0][63];
            for (i = 1; i < 64; i++) begin
                assign theta_out[y][0][i] = theta_in[y][0][i] ^ sum_sheet[4][i] ^ sum_sheet[1][i-1];
                assign theta_out[y][4][i] = theta_in[y][4][i] ^ sum_sheet[3][i] ^ sum_sheet[0][i-1];
            end
        end
    endgenerate

    // Pi
    generate
        for (y = 0; y < 5; y++) begin
            for (x = 0; x < 5; x++) begin
                for (i = 0; i < 64; i++) begin
                    assign pi_out[(2*x+3*y)%5][y][i] = pi_in[y][x][i];
                end
            end
        end
    endgenerate

    // Rho: hardcoded rotation offsets
    function automatic int mod64(input int v);
        return (v + 64) % 64;
    endfunction

    localparam int rho_offsets[5][5] = '{
        '{  0,  1, 62, 28, 27},
        '{ 36, 44,  6, 55, 20},
        '{  3, 10, 43, 25, 39},
        '{ 41, 45, 15, 21,  8},
        '{ 18,  2, 61, 56, 14}
    };

    generate
        for (y = 0; y < 5; y++) begin
            for (x = 0; x < 5; x++) begin
                for (i = 0; i < 64; i++) begin
                    assign rho_out[y][x][i] = rho_in[y][x][mod64(i - rho_offsets[y][x])];
                end
            end
        end
    endgenerate

    // Iota
    generate
        for (y = 1; y < 5; y++) begin
            for (x = 0; x < 5; x++) begin
                for (i = 0; i < 64; i++) begin
                    assign iota_out[y][x][i] = iota_in[y][x][i];
                end
            end
        end
        for (x = 1; x < 5; x++) begin
            for (i = 0; i < 64; i++) begin
                assign iota_out[0][x][i] = iota_in[0][x][i];
            end
        end
        for (i = 0; i < 64; i++) begin
            assign iota_out[0][0][i] = iota_in[0][0][i] ^ round_constant_signal[i];
        end
    endgenerate

endmodule
