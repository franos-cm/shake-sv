-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.ALL;
use work.sha_tb_pkg.all;

entity hash_one_clk_wrapper is
    generic ( 
        algorithm 	: string  := "keccak";
        hashsize 	: integer := 256;
        w 			: integer := 64; 
        pad_mode	: integer := PAD;	
        fifo_mode	: integer := ZERO_WAIT_STATE		
    );
    port (		
        rst 		: in std_logic;
        clk 		: in std_logic;		
        din			: in std_logic_vector(w-1 downto 0);		
        src_read	: out std_logic;
        src_ready	: in  std_logic;
        dout		: out std_logic_vector(w-1 downto 0);
        dst_write	: out std_logic;
        dst_ready	: in std_logic
    );
end entity;

architecture wrapper of hash_one_clk_wrapper is

begin
    abc:  entity work.keccak(structure)
            port map (
                rst         => rst,
                clk         => clk,
                data_in     => din,
                data_out    => dout,
                ready_out   => src_read,
                valid_in    => src_ready,
                valid_out   => dst_write,
                ready_in    => dst_ready
        );
end wrapper;