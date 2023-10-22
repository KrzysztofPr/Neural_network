library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library work;
use work.neuron_package.all;

entity tb_network is
  port (
    test : in std_logic

  );
end entity;

architecture tb_network_bhv of tb_network is
signal clk : std_logic := '1';
signal rst : std_logic := '0';
signal neurout_out : std_logic_vector(16-1 downto 0) := (others => '0');
signal start_calc : std_logic := '0';
signal calc_rdy : std_logic := '0';
 
signal w_in : t_WeightsArr((2*3)-1 downto 0);
signal x_in : t_FeaturesArr(3-1 downto 0);
signal b_in : t_BiasesArr(2-1 downto 0);
signal layer_out : t_BiasesArr(3-1 downto 0);

signal x0_in : t_FeaturesArr(2-1 downto 0)  := (0 => b"1010110011001100", -- 5.4
                                                1 => b"0100100110011001"); --2.3
begin

  clk_proc: process
  begin
   for i in 0 to 150000 loop
    wait for 10 ns;
    clk <= not clk;
   end loop;
  end process;

start_proc : process
begin
  start_calc <= '0';
  wait for 50 ns;
  start_calc <= '1';
  wait for 20 ns;
  start_calc <= '0';
  wait for 400 ns;
end process; 

network_inst : entity work.network
port map(
  clk => clk,
  rst => '0',
  i_StartCalc => start_calc,
  Feature0         => x0_in(0),
  Feature1         => x0_in(1),
  o_Network_rdy    => open,
  ov_NetworkResult => open
);

end architecture;