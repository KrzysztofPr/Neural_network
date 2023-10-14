library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  
library work;
use work.neuron_package.all;

entity network is --main entity
    port (
      clk : in std_logic;
      rst : in std_logic
      );
end entity;

architecture network_rtl of network is
  constant w0_in : t_WeightsArr(6-1 downto 0) := (0 =>
                                                  1 =>
                                                  2 => 
                                                  3 =>
                                                  4 =>
                                                  5 => )
  constant w1_in : t_WeightsArr(6-1 downto 0);

  constant x0_in : t_FeaturesArr(2-1 downto 0);
  constant x1_in : t_FeaturesArr(3-1 downto 0);

  constant b0_in : t_BiasesArr(3-1 downto 0);
  constant b1_in : t_BiasesArr(2-1 downto 0);

begin

  layer0_inst : entity work.Layer
  generic map(
    G_NEURONS          => 3,
    G_INPUT_PER_NEURON => 2,
    G_WEIGHTS_W        => 18,
    G_FEATURE_W        => 16,
    G_BIAS_W           => 16
  )
  port map(
    clk            => clk,
    rst            => rst,
    i_StartLayer   => start_calc,
    o_Layer_rdy    => calc_rdy,
    iv_w           => w_in,
    iv_b           => b_in,
    iv_x           => x_in,
    ov_LayerOutput => open
  );

layer1_inst : entity work.Layer
generic map(
  G_NEURONS          => 2,
  G_INPUT_PER_NEURON => 3,
  G_WEIGHTS_W        => 18,
  G_FEATURE_W        => 16,
  G_BIAS_W           => 16
)
port map(
  clk            => clk,
  rst            => rst,
  i_StartLayer   => start_calc,
  o_Layer_rdy    => calc_rdy,
  iv_w           => w_in,
  iv_b           => b_in,
  iv_x           => x_in,
  ov_LayerOutput => open
);
end architecture;