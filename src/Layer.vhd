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
      i_StartLayer  : in std_logic;
      o_Layer_rdy   : out std_logic;
      iv_w          : in t_WeightsArr((G_INPUT_PER_NEURON*G_NEURONS)-1 downto 0);
      iv_b          : in t_BiasesArr(G_NEURONS-1 downto 0);
      iv_x          : in t_FeaturesArr(G_INPUT_PER_NEURON-1 downto 0);
      ov_LayerOutput: out t_LayerOutArr(G_NEURONS-1 downto 0)
      );
    end entity;
    
architecture Layer_rtl of Layer is
  signal LayerBusy           : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal StartNeurons        : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal Neuron_rdy          : std_logic_vector(G_NEURONS-1 downto 0) := (others => '0');
  signal WeightsToSerialize  : t_WeightsArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal FeaturesToSerialize : t_FeaturesArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal u_CntArr            : t_CounterArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal LayerOutput         : t_LayerOutArr(G_NEURONS-1 downto 0):= (others => (others => '0'));
  signal x_latched           : t_FeaturesArr(iv_x'range) := (others => (others => '0'));
begin
  out_name: process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        o_Layer_rdy <= '0';
      else
        if  (or_reduce(NOT Neuron_rdy) = '0') then
          o_Layer_rdy <= '1';
        else
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
        ov_LayerOutput(ii)      <= (others => '0');
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
            ov_LayerOutput(ii) <= (others => '0');
          elsif (Neuron_rdy(ii) = '1') then
            u_CntArr(ii) <= to_unsigned(ii*G_INPUT_PER_NEURON,u_CntArr(ii)'length);
            LayerBusy(ii)    <= '0';
            ov_LayerOutput(ii) <= LayerOutput(ii);
          else
            u_CntArr(ii) <= u_CntArr(ii);
            LayerBusy(ii)    <= LayerBusy(ii);
            ov_LayerOutput(ii) <= (others => '0');
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
          ov_sigmoid  => LayerOutput(ii),
          i_StartCalc => StartNeurons(ii), 
          o_Calc_rdy  => Neuron_rdy(ii)
          );
        end generate;
end architecture;