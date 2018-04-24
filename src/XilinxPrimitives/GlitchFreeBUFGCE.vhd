-- File              : GlitchFreeBUFGCE.vhd
-- Author            : John Gentile <johncgentile17@gmail.com>
-- Date              : 21.04.2018
-- Last Modified Date: 24.04.2018
-- Last Modified By  : John Gentile <johncgentile17@gmail.com>
--! @file
--! @brief BUFG with glitch-free clock gating
-------------------------------------------------------------------------------
-- Copyright (c) 2018 John Gentile <johncgentile17@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
library UNISIM;
  use UNISIM.vcomponents.all;

--! @details
--! Wraps a `BUFGCTRL` primitive to create a safe, glitch-free Global Clock
--! Buffer with a Clock Enable for 7-series devices; this is used over a
--! regular `BUFGCE` as that primitive's enable gates a clock asynchronously
--! and can cause output clock glitching if the `CE` signal changing violates
--! setup/hold of the buffer due to switching close to an input clock edge.
--!
--! See [Xilinx Guide UG 953: Vivado Design Suite 7 Series FPGA and Zynq-7000
--! All Programmable SoC Libraries Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2017_1/ug953-vivado-7series-libraries.pdf)
--! for more implementation details.
entity GlitchFreeBUFGCE is
  port (
    ClkIn  : in  std_logic; --! Input Clock
    aClkEn : in  std_logic; --! Synchronous/Asynchronous Clock Output enable
    ClkOut : out std_logic  --! Output Clock
  );
end GlitchFreeBUFGCE;

architecture RTL of GlitchFreeBUFGCE is

  component BUFGCTRL
    port (
      CE0     : in  std _logic;
      CE1     : in  std _logic;
      IGNORE0 : in  std _logic;
      IGNORE1 : in  std _logic;
      I0      : in  std _logic;
      I1      : in  std _logic;
      S0      : in  std _logic;
      S1      : in  std _logic;
      O       : out std _logic
    );
  end component;

  signal aClkEn_n : std_logic;

begin

  aClkEn_n <= not aClkEn;

  BUFGCTRL_inst : BUFGCTRL
    generic map (
      INIT_OUT     => 0,      -- Initial value of output `O`
      PRESELECT_I0 => FALSE,  -- Output uses `I0` input
      PRESELECT_I1 => FALSE   -- Output uses `I1` input
    )
    port map (
      -- Enable `Ix` input, though if dynamic, requires meeting setup/hold time
      -- or could result in output clock glitch
      CE0 => '1',
      CE1 => '1',
      -- If high, ignores `Ix` synchronizing input logic and causes MUX to
      -- switch inputs as soon as respective `Sx` select changes (i.e.
      -- asynchronously switch clocks which can cause glitches)
      IGNORE0 => '0',
      IGNORE1 => '0',
      -- Clock inputs where one input clock is always low (disabled state)
      I0 => ClkIn,
      I1 => '0',
      -- Complimentary select inputs where active-high enables input clock.
      -- Most importantly, not meeting setup/hold of these select signals will
      -- *NOT* result in an output clock glitch, though can cause the output
      -- clock to appear one clock cycle later.
      S0 => aClkEn,
      S1 => aClkEn_n,
      -- Output Clock/Signal
      O => ClkOut
    );

end RTL;
