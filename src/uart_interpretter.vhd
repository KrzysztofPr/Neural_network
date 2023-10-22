library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library work;

entity uart_interpretter is
port (
  clk            : in std_logic;
  rst            : in std_logic;
  rx_pin         : in std_logic;
  tx_pin         : out std_logic;
  i_Network_rdy    : in std_logic;
  iv_NetworkResult : in std_logic_vector(8-1 downto 0);
  o_StartNetwork   : out std_logic;
  ov_Feature0    : out std_logic_vector(16-1 downto 0);
  ov_Feature1    : out std_logic_vector(16-1 downto 0)
);
end entity;

architecture uart_interpretter_rtl of uart_interpretter is
  constant C_DataFrameLength : unsigned(8-1 downto 0) := to_unsigned(8,C_DataFrameLength'length);

  signal rec_data_valid : std_logic := '0';
  signal rec_data : std_logic_vector(8-1 downto 0) := (others => '0');

  signal Features : std_logic_vector(32-1 downto 0) := (others => '0');
  signal Receiver_cnt : unsigned(8-1 downto 0) := (others => '0');
  -- count to 4 -> 2 features 16 bit each, 1 uart frame is 8 bit, 2 frames per feature, 4 frames per 2 feautures
  constant C_ReceiverCntValue : unsigned(Receiver_cnt'range) := to_unsigned(4-1, C_ReceiverCntValue'length);
  signal Features_rdy : std_logic := '0';
  --------------------------------------------------------------------------------
begin

uart_inter_proc: process(clk)
begin
  if rising_edge(clk) then
    if (rst = '1') then
      Features <= (others => '0');
      Receiver_cnt <= (others => '0');
      Features_rdy <= '0';
    else
      if (rec_data_valid = '1') then
        if (Receiver_cnt = C_ReceiverCntValue) then
          Receiver_cnt <= (others => '0');
          Features(to_integer(Receiver_cnt + to_unsigned(1,Receiver_cnt'length))*C_DataFrameLength downto to_integer(Receiver_cnt)) <= rec_data;
          Features_rdy <= '1';
        else
          Receiver_cnt <= Receiver_cnt + to_unsigned(1,Receiver_cnt'length);
          Features(to_integer(Receiver_cnt + to_unsigned(1,Receiver_cnt'length))*C_DataFrameLength downto to_integer(Receiver_cnt)) <= rec_data;
          Features_rdy <= '0';
        end if;
      else 
        Features_rdy <= '0';
        Features     <= Features;
        Receiver_cnt <= Receiver_cnt;
      end if;
    end if;
  end if;
end process;
o_StartNetwork <= Features_rdy;
ov_Feature0  <= Features(16-1 downto 0);
ov_Feature1  <= Features(Features'length-1 downto 16);

UartComm_INST : entity work.uart_comm
generic map(
  G_CyclesPerBit => 50000000/115200,
  G_FrameBitsNum => 8
)
port map(
  clk            => clk,
  rst            => rst,
  enable         => '1',
  send_data_start=> i_Network_rdy,
  send_data      => iv_NetworkResult,
  send_buff_full => open,
  rec_data       => rec_data,
  rec_data_valid => rec_data_valid,
  rec_err        => open,
  tx_pin				 => tx_pin,
  rx_pin				 => rx_pin
);

end architecture;