library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library work;
use work.neuron_package.all;

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
 
signal w_in : t_WeightsArr((2*3)-1 downto 0);
signal x_in : t_FeaturesArr(3-1 downto 0);
signal b_in : t_BiasesArr(2-1 downto 0);
signal layer_out : t_BiasesArr(3-1 downto 0);
begin

  clk_proc: process
  begin
   for i in 0 to 150000 loop
    wait for 10 ns;
    clk <= not clk;
   end loop;
  end process;
  -- start_proc : process
  -- begin
  --   start_calc <= '0';
  --   w_in <= (others => '0');
  --   x_in <= (others => '0');
  --   b_in <= (others => '0');
  --   wait for 401 ns;
  --   start_calc <= '1';
  --   w_in <= b"00101_0000000000000"; --sfix 5.13 (18b.)
  --   x_in <=  x"1000"; --ufix 3.13 (16b.)
  --   b_in <=  x"1000"; -- sfix(5.11) (2)
  --   wait for 20 ns;
  --   start_calc <= '1';
  --   w_in <= b"00001_1000000000000";
  --   x_in <=  x"0800";  
  --   b_in <=  x"1000"; 
  --   wait for 20 ns;
  -- end process;
-- neuron_inst : entity work.neuron
-- generic map(
--   G_INPUTS => 2,
--   G_WEIGHTS_W => 18
-- )
-- port map(
--   clk          => clk,
--   rst          => '0',
--   iv_w0        => w_in,
--   iv_bias      => b_in,
--   iv_x0        => x_in,
--   ov_sigmoid   => neurout_out,
--   i_StartCalc  => start_calc,
--   o_Calc_rdy   => calc_rdy
-- );
start_proc : process
begin
  start_calc <= '0';
  w_in <= (0 => b"11100_1100000000000",
           1 => b"00001_1000000000000",
           2 => b"11100_1100000000000",
           3 => b"00001_1000000000000",
           4 => b"11100_1100000000000",
           5 => b"00001_1000000000000"
          );
  x_in <= (0 => x"0800",
           1 =>  x"0800",
           2 =>  x"0800"
          );
  b_in <= (0 => x"1000",
           1 => x"1000"
           );
  wait for 50 ns;
  start_calc <= '1';
  wait for 20 ns;
  start_calc <= '0';
  wait for 400 ns;
end process; 
layer_inst : entity work.Layer
generic map(
  G_NEURONS          => 2,
  G_INPUT_PER_NEURON => 3,
  G_WEIGHTS_W        => 18,
  G_FEATURE_W        => 16,
  G_BIAS_W           => 16
)
port map(
  clk            => clk,
  rst            => '0',
  i_StartLayer   => start_calc,
  o_Layer_rdy    => calc_rdy,
  iv_w           => w_in,
  iv_b           => b_in,
  iv_x           => x_in,
  ov_LayerOutput => open
);

end architecture;