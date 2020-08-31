-- Hex value to 7-segment display combinatorial decoder w/pinout:
--      0
--     ---
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
--
library ieee;
  use ieee.std_logic_1164.all;

entity seven_seg_disp is
  port (
    hex_val : in  std_logic_vector(3 downto 0);
    LED     : out std_logic_vector(6 downto 0)
  );
end entity seven_seg_disp;

architecture rtl of seven_seg_disp is
begin

  with hex_val select
    LED <= "1111001" when "0001", -- 1
           "0100100" when "0010", -- 2
           "0110000" when "0011", -- 3
           "0011001" when "0100", -- 4
           "0010010" when "0101", -- 5
           "0000010" when "0110", -- 6
           "1111000" when "0111", -- 7
           "0000000" when "1000", -- 8
           "0010000" when "1001", -- 9
           "0001000" when "1010", -- A
           "0000011" when "1011", -- B
           "1000110" when "1100", -- C
           "0100001" when "1101", -- D
           "0000110" when "1110", -- E
           "0001110" when "1111", -- F
           "1000000" when others; -- 0

end architecture rtl;
