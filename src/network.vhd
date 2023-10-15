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
  --------------------------------------------------------------------------------
  -- network trained in neural.py file, all the coefficients are calculated in neural.py file
  --------------------------------------------------------------------------------
  --1st hidden layer (3 neurons)
  constant w0_in : t_WeightsArr(6-1 downto 0) := (0 => b"00010_1011101000100",
                                                  1 => b"10111_0110001101101",
                                                  2 => b"00000_0001101001011",
                                                  3 => b"10111_0010011010101",
                                                  4 => b"00100_0011000111111",
                                                  5 => b"11000_0100111010001");
  --2st hidden layer (2 neurons)
  constant w1_in : t_WeightsArr(6-1 downto 0) := (0 => b"10101_1011100100000",
                                                  1 => b"10111_0001110111011",
                                                  2 => b"01001_0011010110101",
                                                  3 => b"00101_1110011001100",
                                                  4 => b"01000_1001111010100",
                                                  5 => b"10100_1110001000000"
                                                  );
  --3rd output layer
  constant w2_in : t_WeightsArr(6-1 downto 0) := (0 => b"01010_1100000101010",
                                                  1 => b"10101_1001101111010"
                                                  );
  constant x0_in : t_FeaturesArr(2-1 downto 0);
  constant x1_in : t_FeaturesArr(3-1 downto 0);

  constant b0_in : t_BiasesArr(3-1 downto 0) := (0 => b"1011001011100001",
                                                 1 => b"0001000010101110",
                                                 2 => b"1010011101111110",
                                                 );
  constant b1_in : t_BiasesArr(2-1 downto 0) := (0 => b"1100101111010011",
                                                 1 => b"1110011001000101");
  constant b2_in : t_BiasesArr(1-1 downto 0) := (0 => b"1011011001101010");
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