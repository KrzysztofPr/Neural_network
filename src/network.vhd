library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  
library work;
use work.neuron_package.all;

entity network is --main entity
    port (
      clk : in std_logic;
      rst : in std_logic;
      i_StartCalc : in std_logic
      );
end entity;

architecture network_rtl of network is
  --------------------------------------------------------------------------------
  -- network trained in neural.py file, all the coefficients are calculated in neural.py file
  --------------------------------------------------------------------------------
  --1st hidden layer (3 neurons)
  constant w0_in : t_WeightsArr(6-1 downto 0) := (0 => b"000101011101000100", --53504
                                                  1 => b"101110110001101101", --
                                                  2 => b"000000001101001011",
                                                  3 => b"101110010011010101",
                                                  4 => b"001000011000111111",
                                                  5 => b"110000100111010001");
  --2st hidden layer (2 neurons)
  constant w1_in : t_WeightsArr(6-1 downto 0) := (0 => b"101011011100100000",
                                                  1 => b"101110001110111011",
                                                  2 => b"010010011010110101",
                                                  3 => b"001011110011001100",
                                                  4 => b"010001001111010100",
                                                  5 => b"101001110001000000" 
                                                  );
  --3rd output layer
  -- constant w2_in : t_WeightsArr(6-1 downto 0) := (0 => b"01010_1100000101010",
  --                                                 1 => b"10101_1001101111010"
  --                                                 );
  constant b0_in : t_BiasesArr(3-1 downto 0) := (0 => b"1011001011100001",
                                                 1 => b"0001000010101110",
                                                 2 => b"1010011101111110"
                                                 );
  constant b1_in : t_BiasesArr(2-1 downto 0) := (0 => b"1100101111010011",
                                                 1 => b"1110011001000101");
  constant b2_in : t_BiasesArr(1-1 downto 0) := (0 => b"1011011001101010");
  -- test values
  constant x0_in : t_FeaturesArr(2-1 downto 0) := (0 => b"1000011001100110", -- 4.2
                                                   1 => b"0010100110011001"); --1.3
--------------------------------------------------------------------------------
-- others
  signal FirstLayer_rdy       : std_logic := '0';
  signal FirstLayer_rdy_reg   : std_logic := '0';
  signal SecondLayer_rdy      : std_logic := '0';
  signal FirstLayerResult     : t_LayerOutArr(3-1 downto 0) := (others => (others => '0'));
  signal FirstLayerResult16b  : t_FeaturesArr(3-1 downto 0) := (others => (others => '0'));
  signal SecondLayerResult    : t_LayerOutArr(2-1 downto 0) := (others => (others => '0'));

begin
  NetworkControl_proc: process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        FirstLayerResult16b <= (others => (others => '0'));
        FirstLayer_rdy_reg  <= '0';
      else
        FirstLayerResult16b <= (0 => (b"000" & FirstLayerResult(0)),
                                1 => (b"000" & FirstLayerResult(1)),
                                2 => (b"000" & FirstLayerResult(2))   );
        FirstLayer_rdy_reg <= FirstLayer_rdy;
      end if;
    end if;
  end process;

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
    i_StartLayer   => i_StartCalc,
    o_Layer_rdy    => FirstLayer_rdy,
    iv_w           => w0_in,
    iv_b           => b0_in,
    iv_x           => x0_in,
    ov_LayerOutput => FirstLayerResult --!!! ufix  0.16!!! TODO CONVERT!
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
  i_StartLayer   => FirstLayer_rdy_reg,
  o_Layer_rdy    => SecondLayer_rdy,
  iv_w           => w1_in,
  iv_b           => b1_in,
  iv_x           => FirstLayerResult16b,
  ov_LayerOutput => SecondLayerResult
);
end architecture;