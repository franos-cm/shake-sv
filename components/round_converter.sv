import keccak_pkg::*;

module absorber (
    input  logic absorb_enable,
    input  logic [1087:0] rate_data,
    input k_state round_out,
    input  logic [1599:0] state_reg_out,
    output  logic [1599:0] state_reg_in,
    output k_state round_in
);

    genvar row, col, i;
    generate
      for (row = 0; row < 5; row++) begin
        for (col = 0; col < 5; col++) begin
          for (i = 0; i < 64; i++) begin : assign_bits
            localparam int idx = row*5*64 + col*64 + i;
            if ((row < 3) || (row == 3 && col < 2)) begin
              // Rate part (first 1088 bits)
              assign round_in[row][col][i] =
                state_reg_out[idx] ^ (rate_data[idx] & absorb_enable);
            end else begin
              // Capacity part (remaining 512 bits)
              assign round_in[row][col][i] = state_reg_out[idx];
            end
          end
        end
      end
    endgenerate

    genvar row2, col2, i2;
    generate
      for (row2 = 0; row2 < 5; row2++) begin
        for (col2 = 0; col2 < 5; col2++) begin
          for (i2 = 0; i2 < 64; i2++) begin
            localparam int idx = row2*5*64 + col2*64 + i2;
            assign state_reg_in[idx] = round_out[row2][col2][i2];
          end
        end
      end
    endgenerate

endmodule

