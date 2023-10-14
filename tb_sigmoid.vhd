library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library work;

entity tb_sigmoid is
  port (
    test : in std_logic

  );
end entity;

architecture tb_sigmoid_bhv of tb_sigmoid is
signal clk : std_logic := '1';
signal rst : std_logic := '0';
signal neurout_out : std_logic_vector(16-1 downto 0) := (others => '0');
signal start_calc : std_logic := '0';
signal calc_rdy : std_logic := '0';

signal w_in : std_logic_vector(18-1 downto 0) := (others => '0');
signal x_in : std_logic_vector(16-1 downto 0) := (others => '0');
signal b_in : std_logic_vector(16-1 downto 0) := (others => '0');

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
    w_in <= (others => '0');
    x_in <= (others => '0');
    b_in <= (others => '0');
    wait for 401 ns;
    start_calc <= '1';
    w_in <= b"00101_0000000000000"; --sfix 5.13 (18b.)
    x_in <=  x"1000"; --ufix 3.13 (16b.)
    b_in <=  x"1000"; -- sfix(5.11) (2)
    wait for 20 ns;
    start_calc <= '1';
    w_in <= b"00001_1000000000000";
    x_in <=  x"0800";  
    b_in <=  x"1000"; 
    wait for 20 ns;

  end process;

neuron_inst : entity work.neuron
generic map(
  G_INPUTS => 2,
  G_WEIGHTS_W => 18
)
port map(
  clk          => clk,
  rst          => '0',
  iv_w0        => w_in,
  iv_bias      => b_in,
  iv_x0        => x_in,
  ov_sigmoid   => neurout_out,
  i_StartCalc  => start_calc,
  o_Calc_rdy   => calc_rdy
);

end architecture;