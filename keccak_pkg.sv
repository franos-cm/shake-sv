package keccak_pkg;

  // Constants
  parameter int num_plane = 5;
  parameter int num_sheet = 5;
  parameter int w = 64;
  parameter int state_width = 1600;
  parameter int RATE_SHAKE256 = 1088;
  parameter int RATE_SHAKE128 = 1344;
  parameter int CAP_SHAKE256 = state_width - RATE_SHAKE256;
  parameter int CAP_SHAKE128 = state_width - RATE_SHAKE128;

  localparam logic [10:0] RATE_SHAKE256_VEC = logic'(RATE_SHAKE256);
  localparam logic [10:0] RATE_SHAKE128_VEC = logic'(RATE_SHAKE128);
  localparam logic [10:0] CAP_SHAKE256_VEC = logic'(CAP_SHAKE256);
  localparam logic [10:0] CAP_SHAKE128_VEC = logic'(CAP_SHAKE128);
  localparam logic [1:0] SHAKE256_MODE_VEC = 2'b11;
  localparam logic [1:0] SHAKE128_MODE_VEC = 2'b10;

endpackage