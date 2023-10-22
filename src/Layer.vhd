library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  
use ieee.std_logic_misc.all;  
library work;
use work.neuron_package.all;

entity Layer is 
  generic (
    G_NEURONS          : natural := 3;
    G_INPUT_PER_NEURON : natural := 2;
    G_WEIGHTS_W        : natural := 18;
    G_FEATURE_W        : natural := 16;
    G_BIAS_W           : natural := 16
    );
    port (
      clk           : in std_logic;
      rst           : in std_logic;
      i_StartLayer  : in std_logic := '0';
      o_Layer_rdy   : out std_logic := '0';
      iv_w          : in t_WeightsArr((G_INPUT_PER_NEURON*G_NEURONS)-1 downto 0);
      iv_b          : in t_BiasesArr(G_NEURONS-1 downto 0);
      iv_x          : in t_FeaturesArr(G_INPUT_PER_NEURON-1 downto 0);
      ov_LayerOutput: out t_LayerOutArr(G_NEURONS-1 downto 0) := (others => (others => '0'))
      );
    end entity;
    
architecture Layer_rtl of Layer is
  component rom_sigmoid --questa problem
    port
      (
      address: in std_logic_vector (15 downto 0);
      clock  : in std_logic  := '1';
      q      : out std_logic_vector (12 downto 0)
      );
  end component;
  --------------------------------------------------------------------------------
  signal LayerBusy           : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal StartNeurons        : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal Neuron_rdy          : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal WeightsToSerialize  : t_WeightsArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal FeaturesToSerialize : t_FeaturesArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal u_CntArr            : t_CounterArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal LayerOutput         : t_FeaturesArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal x_latched           : t_FeaturesArr(iv_x'range) := (others => (others => '0'));
  signal NeuronsResults      : t_FeaturesArr(G_NEURONS-1 downto 0) := (others => (others => '0'));

  signal SigmoidIn_cnt : unsigned(8-1 downto 0) := (others => '0');
  signal Neurons_rdy : std_logic := '0';
  signal Neurons_rdylatched : std_logic := '0';
  signal sigmoid_addr   : std_logic_vector(16-1 downto 0) := (others => '0');
  signal sigmoid_output : std_logic_vector(13-1 downto 0) := (others => '0');
  signal SigmoidOut_cnt : unsigned(8-1 downto 0) := (others => '0');
  signal SigmoidOut_cnt_en   : std_logic := '0';
  signal SigmoidOut_cnt_en_r : std_logic := '0';
  signal SigmoidOut_cnt_en_r1: std_logic := '0';
begin

  rom_sigm : rom_sigmoid
    port map(
      address	=> sigmoid_addr,
      clock	  => clk,
      q		    => sigmoid_output
    );

  sigmoidCtrl_proc: process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        SigmoidIn_cnt        <= (others => '0');
        Neurons_rdylatched   <= '0';
        NeuronsResults       <= (others => (others => '0'));
        sigmoid_addr         <= (others => '0');
        SigmoidOut_cnt       <= (others => '0');
        SigmoidOut_cnt_en    <= '0';
        SigmoidOut_cnt_en_r  <= '0';
        SigmoidOut_cnt_en_r1 <= '0';
        o_Layer_rdy          <= '0';
        ov_LayerOutput       <= (others => (others => '0'));
      else
        if (or_reduce(NOT Neuron_rdy) = '0') then
          SigmoidIn_cnt <= (others => '0');
          Neurons_rdylatched <= '1';
          NeuronsResults <= LayerOutput;
        end if;

        if (Neurons_rdylatched = '1') then
          if (SigmoidIn_cnt < G_NEURONS-1) then
            sigmoid_addr <= NeuronsResults(to_integer(SigmoidIn_cnt));
            SigmoidIn_cnt  <= SigmoidIn_cnt + to_unsigned(1,SigmoidIn_cnt'length);
          elsif (SigmoidIn_cnt = G_NEURONS-1) then
            sigmoid_addr <= NeuronsResults(to_integer(SigmoidIn_cnt));
            Neurons_rdylatched <= '0';
          else
            sigmoid_addr <= sigmoid_addr;
            Neurons_rdylatched <= Neurons_rdylatched;
          end if;
        else  
          sigmoid_addr <= (others => '0');
          SigmoidIn_cnt  <= (others => '0');
        end if;

        if (Neurons_rdylatched = '1') then
          SigmoidOut_cnt_en <= '1';
        end if;
        SigmoidOut_cnt_en_r  <= SigmoidOut_cnt_en;
        SigmoidOut_cnt_en_r1 <= SigmoidOut_cnt_en_r;

        if (SigmoidOut_cnt_en_r1 = '1') then
          if (SigmoidOut_cnt < G_NEURONS-1) then
            SigmoidOut_cnt <= SigmoidOut_cnt + to_unsigned(1,SigmoidOut_cnt'length);
            ov_LayerOutput(to_integer(SigmoidOut_cnt)) <= sigmoid_output;
            o_Layer_rdy <= '0';
          elsif (SigmoidOut_cnt = G_NEURONS-1) then
            ov_LayerOutput(to_integer(SigmoidOut_cnt)) <= sigmoid_output;
            SigmoidOut_cnt <= (others => '0');
            SigmoidOut_cnt_en    <= '0';
            SigmoidOut_cnt_en_r  <= '0';
            SigmoidOut_cnt_en_r1 <= '0';
            o_Layer_rdy <= '1';
          else
            SigmoidOut_cnt <= (others => '0');
            SigmoidOut_cnt_en    <= '0';
            SigmoidOut_cnt_en_r  <= '0';
            SigmoidOut_cnt_en_r1 <= '0';
            o_Layer_rdy <= '0';
          end if;
        else
          SigmoidOut_cnt <= (others => '0');
          o_Layer_rdy <= '0';
        end if;

      end if;
    end if;
  end process;

  Layer_proc: process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then 
        for ii in 0 to G_NEURONS-1 loop
        LayerBusy(ii)           <= '0';
        u_CntArr(ii)            <= (others => '0');
        StartNeurons(ii)        <= '0'; 
        WeightsToSerialize(ii)  <= (others => '0');
        FeaturesToSerialize(ii) <= (others => '0');
        end loop; 
      else
        if (i_StartLayer = '1') then
          x_latched <= iv_x;
        else
          x_latched <= x_latched;
        end if;
        for ii in 0 to G_NEURONS-1 loop
          if (i_StartLayer = '1') then
            LayerBusy(ii)    <= '1';
            u_CntArr(ii) <= to_unsigned(ii*G_INPUT_PER_NEURON,u_CntArr(ii)'length);
          elsif (Neuron_rdy(ii) = '1') then
            u_CntArr(ii) <= to_unsigned(ii*G_INPUT_PER_NEURON,u_CntArr(ii)'length);
            LayerBusy(ii)    <= '0';
          else
            u_CntArr(ii)     <= u_CntArr(ii);
            LayerBusy(ii)    <= LayerBusy(ii);
          end if; 
          if (LayerBusy(ii) = '1') then
            if (u_CntArr(ii) < to_unsigned((G_INPUT_PER_NEURON*ii)+G_INPUT_PER_NEURON-1,u_CntArr(ii)'length)) then
              StartNeurons(ii) <= '1'; -- one tap start
              WeightsToSerialize(ii) <= iv_w(to_integer(u_CntArr(ii)));
              u_CntArr(ii) <=  u_CntArr(ii) + to_unsigned(1,u_CntArr(ii)'length);
              FeaturesToSerialize(ii) <= x_latched(to_integer(u_CntArr(ii))-(ii*G_INPUT_PER_NEURON));
            elsif (u_CntArr(ii) = to_unsigned((G_INPUT_PER_NEURON*ii)+G_INPUT_PER_NEURON-1,u_CntArr(ii)'length)) then
              StartNeurons(ii) <= '0'; -- one tap start
              WeightsToSerialize(ii) <= iv_w(to_integer(u_CntArr(ii)));
              FeaturesToSerialize(ii) <= x_latched(to_integer(u_CntArr(ii))-(ii*G_INPUT_PER_NEURON));
              u_CntArr(ii) <=  u_CntArr(ii) + to_unsigned(1,u_CntArr(ii)'length);
            else
              StartNeurons(ii) <= StartNeurons(ii);
              WeightsToSerialize(ii) <=  WeightsToSerialize(ii);
              u_CntArr(ii) <= u_CntArr(ii);
              FeaturesToSerialize(ii) <= FeaturesToSerialize(ii);
            end if;
          else
            StartNeurons(ii)        <= '0'; 
            WeightsToSerialize(ii)  <= (others => '0');
            FeaturesToSerialize(ii) <= (others => '0');
          end if;
        end loop;
      end if;
    end if;
  end process;

neuron_gen: for ii in 0 to G_NEURONS-1 generate
  Neuron_INST : entity work.neuron
  generic map(
    G_INPUTS => G_INPUT_PER_NEURON,
    G_WEIGHTS_W => G_WEIGHTS_W
    )
    port map(
      clk         => clk,
      rst         => rst,
      iv_w0       => WeightsToSerialize(ii),
      iv_bias     => iv_b(ii),
      iv_x0       => FeaturesToSerialize(ii),
      ov_address  => LayerOutput(ii),
      i_StartCalc => StartNeurons(ii), 
      o_Calc_rdy  => Neuron_rdy(ii)
      );
end generate;
end architecture;