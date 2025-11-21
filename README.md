# Overview

This project is a SystemVerilog implementation of the Keccak cryptographic hash function, specifically the SHAKE128 and SHAKE256 variants.

It is heavily inspired by [a similar project in VHDL](https://github.com/GMUCERG/SHAKE), and uses the exact same interface and handshake protocol.
Therefore, reading the documentation for the original project is highly recommended.


# Key Points

### Configurability
The design unit can be configured at runtime to perform either the SHAKE128 or SHAKE256 functions. Naturally, since these are extendable outputs functions (XOFs), both the input and output sizes are similarly configurable.

### Pipelined design

The design unit is divided into three pipeline stages, respectively responsible for (1) loading the input, (2) performing the Keccak permutation function, and (3) writing the result. This allows, for example, for the next data block (belonging either to the same hash operation, or the next one) to be loaded into the module before it has finished performing the current permutation.

### Padding and masking

The design unit automatically takes care of performing the padding mandated by the Keccak specification. That is, it appends the input data with the correct domain separator, followed by the 10*1 padding pattern, until the complete bitstring is a whole multiple of the rate $r$ of the current mode.

Similarly, if the output size is not a whole multiple of the design unit's port width (64), the extra output bits are masked to zero.

# Constraints

### SHAKE128 and SHAKE256 only
Currently, this module is designed specifically for performing SHAKE128 and SHAKE256, and does not support other Keccak-based standards like SHA-3 or cSHAKE.
  
### Byte-aligned inputs and outputs

To maintain consistency with the original module, although both input and output sizes are specified on a bit level, these values are expected to be a whole number of bytes. If not, it is possible that both input padding and output zero-masking will not perform as expected.

### Toolchain differences

Having simulated this design using several different tools, it is my experience that not all SystemVerilog features used in this design are supported by all toolchains.

To give an example, although parametrized classes with static methods can be both simulated (and even synthesised) in Vivado/Xsim 2024.2, the same is not true for Quartus/Questa 2024.1. In that sense, both Vivado and Active-HDL have been verified to correctly simulate this design as is.

In any case, the necessary adjustments should be minimal. Most tools support simulating SystemVerilog functions, so converting the utility class used in the design into a series of standalone functions is straightforward.


# Project Structure
- `shake-sv/`
  
  - `components/`: simple components used throughout the design unit. Includes mostly standard components like `regn.sv` and `coutern.sv`, but also ones specific to Keccak, such as `round.sv` and `padding_gen.sv`.

  - `stages/`: pipeline stages  — **load**, **permute**, and **dump** — each split into `*_datapath.sv` and `*_fsm.sv` modules that are integrated in `*_stages.sv`.

  - `keccak_pkg.sv`: package that defines useful constants, such as the rate and capacity for each mode.

  - `keccak.sv`: Top level that integrates all pipeline stages.
