library ieee;
  use ieee.std_logic_1164.all;

  use work.pkg_net.all;

entity tb_vnic is
end entity;

architecture behav of tb_vnic is
begin


  CS_loopback: process
    variable rx_length : integer := 0;
  begin
    rx_length := F_receive_pkt;
    wait for 1 ns;
    for i in 0 to rx_length - 1 loop
      p_tx_buff(i) := p_rx_buff(i);
    end loop;
    wait for 1 ns;
    if F_send_pkt(rx_length) > 0 then
      report "Error in sending packet!" severity failure;
    end if;
    wait;
  end process;

end architecture behav;
