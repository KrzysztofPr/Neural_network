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
  constant w0_in : t_WeightsArr(6-1 downto 0) := (0 => b"000101100111000100", --53504
                                                  1 => b"111001110011011110", --
                                                  2 => b"000100100010110010",
                                                  3 => b"111100001110011011",
                                                  4 => b"110111110000111111",
                                                  5 => b"010101110011011010");

  constant w1_in : t_WeightsArr(6-1 downto 0) := (0 => b"101111100011100111",
                                                  1 => b"110001100001000100",
                                                  2 => b"100010111001100010",
                                                  3 => b"101101000010111110",
                                                  4 => b"101101001101101000",
                                                  5 => b"110101010101001000" 
                                                  );
                                                  
  constant w2_in : t_WeightsArr(2-1 downto 0) := (0 => b"101011011101011111",
                                                  1 => b"101101011111110110"  );
  --3rd output layer
  constant b0_in : t_BiasesArr(3-1 downto 0) := (0 => b"1010110111011111",
                                                 1 => b"1011101001101001",
                                                 2 => b"0000000011000000"
                                                 );
  constant b1_in : t_BiasesArr(2-1 downto 0) := (0 => b"0010111110011100",
                                                 1 => b"0011110010110000");
                                                                     
  constant b2_in : t_BiasesArr(1-1 downto 0) := (0 => b"0101000010100000");
  -- test values
  constant x0_in : t_FeaturesArr(2-1 downto 0) := (0 => b"1010110011001100", -- 5.4
                                                   1 => b"0100100110011001"); --2.3
--------------------------------------------------------------------------------
-- others
  signal FirstLayer_rdy          : std_logic := '0';
  signal FirstLayer_rdy_reg      : std_logic := '0';
  signal SecondLayer_rdy         : std_logic := '0';
  signal SecondLayer_rdy_reg     : std_logic := '0';

  signal FirstLayerResult        : t_LayerOutArr(3-1 downto 0) := (others => (others => '0'));
  signal FirstLayerResult16b     : t_FeaturesArr(3-1 downto 0) := (others => (others => '0'));
  signal SecondLayerResult       : t_LayerOutArr(2-1 downto 0) := (others => (others => '0'));
  signal SecondLayerResult16b    : t_FeaturesArr(2-1 downto 0) := (others => (others => '0'));

  signal ThirdLayerResult       : t_LayerOutArr(1-1 downto 0) := (others => (others => '0'));
  signal ThirdLayer_rdy         : std_logic := '0';


begin
  NetworkControl_proc: process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        FirstLayerResult16b  <= (others => (others => '0'));
        FirstLayer_rdy_reg   <= '0';
        SecondLayer_rdy_reg  <= '0';
        SecondLayerResult16b <= (others => (others => '0'));
      else
        FirstLayerResult16b <= (0 => (b"000" & FirstLayerResult(0)),
                                1 => (b"000" & FirstLayerResult(1)),
                                2 => (b"000" & FirstLayerResult(2))   );
        FirstLayer_rdy_reg <= FirstLayer_rdy;
        --------------------------------------------------------------------------------
        SecondLayerResult16b <= (0 => (b"000" & SecondLayerResult(0)),
                                 1 => (b"000" & SecondLayerResult(1))  );
        SecondLayer_rdy_reg <= SecondLayer_rdy;
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
    ov_LayerOutput => FirstLayerResult 
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

layer2_inst : entity work.Layer
generic map(
  G_NEURONS          => 1,
  G_INPUT_PER_NEURON => 2,
  G_WEIGHTS_W        => 18,
  G_FEATURE_W        => 16,
  G_BIAS_W           => 16
)
port map(
  clk            => clk,
  rst            => rst,
  i_StartLayer   => SecondLayer_rdy_reg,
  o_Layer_rdy    => ThirdLayer_rdy,
  iv_w           => w2_in,
  iv_b           => b2_in,
  iv_x           => SecondLayerResult16b,
  ov_LayerOutput => ThirdLayerResult
);
--output < 0.5 -> class 1
--output >=0.5 -> class 2
end architecture;