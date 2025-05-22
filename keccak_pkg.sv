package keccak_pkg;

  // Constants
  localparam int num_plane = 5;
  localparam int num_sheet = 5;
  localparam int w = 64;
  localparam int w_byte_size = w / 8;
  localparam int w_bit_width = $clog2(w);
  localparam int w_byte_width = $clog2(w) - 3;

  localparam int STATE_WIDTH = 1600;
  localparam int RATE_SHAKE256 = 1088;
  localparam int RATE_SHAKE128 = 1344;
  localparam int CAP_SHAKE256 = STATE_WIDTH - RATE_SHAKE256;
  localparam int CAP_SHAKE128 = STATE_WIDTH - RATE_SHAKE128;

  localparam logic [10:0] RATE_SHAKE256_VEC = 11'(RATE_SHAKE256);
  localparam logic [10:0] RATE_SHAKE128_VEC = 11'(RATE_SHAKE128);
  localparam logic [10:0] CAP_SHAKE256_VEC = 11'(CAP_SHAKE256);
  localparam logic [10:0] CAP_SHAKE128_VEC = 11'(CAP_SHAKE128);
  localparam logic [1:0] SHAKE256_MODE_VEC = 2'b11;
  localparam logic [1:0] SHAKE128_MODE_VEC = 2'b10;

  
  // I believe this is synthethizable in Vivado
  // Otherwise, we should turn it into functions
  class EndianSwitcher #(parameter int WIDTH = 64);
    // Static function: reverses the byte order
    static function logic [WIDTH-1:0] switch(input logic [WIDTH-1:0] x);
      const int NUM_BYTES = WIDTH / 8;
      logic [WIDTH-1:0] result;

      for (int i = 0; i < NUM_BYTES; i++) begin
        result[i*8 +: 8] = x[(NUM_BYTES - 1 - i)*8 +: 8];
      end

      return result;
    endfunction
  endclass

endpackage