library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  

package neuron_package is
  constant C_Weights_W : natural := 18;
  constant C_Features_W : natural := 16;
  constant C_Biases_W : natural := 16;

  type t_WeightsArr is array(natural range <>) of std_logic_vector(C_Weights_W-1 downto 0);

  type t_FeaturesArr is array(natural range <>) of std_logic_vector(C_Features_W-1 downto 0);

  type t_BiasesArr is array(natural range <>) of std_logic_vector(C_Biases_W-1 downto 0);

  type t_CounterArr is array(natural range <>) of unsigned(16-1 downto 0);

  type t_LayerOutArr is array(natural range <>) of std_logic_vector(13-1 downto 0);


end neuron_package;