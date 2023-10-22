library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library work;

entity Network_Controller is
port (
  clk        : in std_logic;
  n_rst      : in std_logic;
  rx_pin     : in std_logic;
  tx_pin     : out std_logic
);
end entity;

architecture Network_Controller_rtl of Network_Controller is

 signal rst           : std_logic := '0';
 signal Features_rdy  : std_logic := '0';
 signal Feature0      : std_logic_vector(16-1 downto 0) := (others => '0');
 signal Feature1      : std_logic_vector(16-1 downto 0) := (others => '0');
 signal NetworkResult : std_logic_vector(13-1 downto 0) := (others => '0');

 constant ClassThreshold : std_logic_vector(13-1 downto 0) := std_logic_vector(to_unsigned(4096,13));
 signal   NetworkResultClass : std_logic_vector(8-1 downto 0) := (others => '0'); -- 0 class 1 , 1 class 2 
 signal   Network_rdy     : std_logic := '0';
 signal   Network_rdy_reg : std_logic := '0';
begin

  rst <= NOT n_rst; -- reset is active on '0' on dev board 
NetCtrl_proc: process(clk)
begin
  if rising_edge(clk) then
    if (rst = '1') then
      Network_rdy_reg    <= '0';
      NetworkResultClass <= (others => '0');
    else
      Network_rdy_reg <= Network_rdy;
      if (unsigned(NetworkResult) < unsigned(ClassThreshold)) then
        NetworkResultClass <= std_logic_vector(to_unsigned(1,8));
      else
        NetworkResultClass <= std_logic_vector(to_unsigned(2,8));
      end if;
    end if;
  end if;
end process;

Network_INST : entity work.network
port map(
  clk              => clk,
  rst              => rst,
  i_StartCalc      => Features_rdy,
  Feature0         => Feature0,
  Feature1         => Feature1,
  o_Network_rdy    => Network_rdy,
  ov_NetworkResult => NetworkResult
);

uart_interprett_INST : entity work.uart_interpretter
port map(
  clk              => clk,
  rst              => rst,
  rx_pin           => rx_pin,
  tx_pin           => tx_pin,
  i_Network_rdy    => Network_rdy_reg,
  iv_NetworkResult => NetworkResultClass,
  o_StartNetwork   => Features_rdy,
  ov_Feature0      => Feature0,
  ov_Feature1      => Feature1
);

end architecture;