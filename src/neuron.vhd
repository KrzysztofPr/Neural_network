library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
-- library rom_sigmoid;
entity neuron is
generic (
G_INPUTS : natural := 3;
G_WEIGHTS_W : natural := 18
);
port (
clk        : in std_logic;
rst        : in std_logic;
iv_w0      : in std_logic_vector(G_WEIGHTS_W-1 downto 0);
iv_bias    : in std_logic_vector(16-1 downto 0);
iv_x0      : in std_logic_vector(16-1 downto 0); -- 16 bit cecha
ov_address : out std_logic_vector(16-1 downto 0);
i_StartCalc: in std_logic;
o_Calc_rdy : out std_logic
);
end entity;
architecture neuron_rtl of neuron is
signal MulInB           : signed(iv_x0'length downto 0) := (others => '0');
signal MulInA           : signed(G_WEIGHTS_W-1 downto 0) := (others => '0');
signal MulOut           : signed(35-1 downto 0) := (others => '0');
signal MulResultsStored : std_logic := '0';
signal StartCalc_reg    : std_logic := '0';
signal CalcBusy         : std_logic := '0';
signal Calc_rdy         : std_logic_vector(4-1 downto 0) := (others => '0');
signal Sum_cnt          : unsigned(G_WEIGHTS_W-1 downto 0) := (others => '0');
signal Arr_cnt          : unsigned(16-1 downto 0) := (others => '0');
signal Sum              : signed(G_WEIGHTS_W-1+2 downto 0) := (others => '0');
signal Sum_with_bias    : signed(G_WEIGHTS_W-1+2 downto 0) := (others => '0');
signal Sum_saturated    : signed(G_WEIGHTS_W-1+2 downto 0) := (others => '0');
signal s_SumRes         : signed(Sum'length-1 downto 0) := (others => '0');
signal bias_latch       : std_logic_vector(iv_bias'length-1 downto 0) := (others => '0');
-----
type t_inputarray is array (G_INPUTS-1 downto 0) of signed(G_WEIGHTS_W-1 downto 0);
signal MulResArr    : t_inputarray  := (others => (others => '0'));

constant SumMaxValuePos4 : signed(Sum'length-1 downto 0) := to_signed(4096,G_WEIGHTS_W+2); -- 4 in Q10.10 signed
constant SumMinValueNeg4 : signed(Sum'length-1 downto 0) := to_signed(1_044_480,G_WEIGHTS_W+2); -- -4 in Q10.10 signed
begin
neuron_proc: process(clk)
begin
if rising_edge(clk) then
  if (rst = '1') then
    MulResArr        <= (others => (others => '0'));
    Arr_cnt          <= (others => '0');
    MulResultsStored <= '0';
    Sum              <= (others => '0');
    Sum_cnt          <= (others => '0');
    MulInA           <= (others => '0');
    MulInB           <= (others => '0');
    MulOut           <= (others => '0');
    StartCalc_reg    <= '0';
    CalcBusy         <= '0';
  else
    if (i_StartCalc = '1') then
      bias_latch <= iv_bias;
    end if;
    MulInA <= signed(iv_w0); -- signed Q5.13
    MulInB <= signed('0' & iv_x0); -- unsigned Q3.13
    MulOut <= MulInA * MulInB;
    
    StartCalc_reg  <= i_StartCalc;
    
    if (StartCalc_reg = '1') then
      CalcBusy         <= '1';
    end if;
    
    if (CalcBusy = '1') then -- multiplier ready
      if (Arr_cnt = to_unsigned(G_INPUTS-1,Arr_cnt'length)) then
        MulResArr(to_integer(Arr_cnt)) <= MulOut(MulOut'length-2 downto MulOut'length-G_WEIGHTS_W-1); --signed Q8.10
        Arr_cnt <= Arr_cnt + to_unsigned(1,Arr_cnt'length);
        MulResultsStored <= '1';
      elsif (Arr_cnt < to_unsigned(G_INPUTS-1,Arr_cnt'length)) then
        MulResArr(to_integer(Arr_cnt)) <= MulOut(MulOut'length-2 downto MulOut'length-G_WEIGHTS_W-1); --signed Q8.10
        Arr_cnt <= Arr_cnt + to_unsigned(1,Arr_cnt'length);
        MulResultsStored <= '0';
      else
        MulResArr <=MulResArr; 
        Arr_cnt <= Arr_cnt;
        MulResultsStored <= MulResultsStored ;
      end if;
      
      if (MulResultsStored = '1') then -- start adder tree
        if (Sum_cnt = to_unsigned(G_INPUTS-1,Arr_cnt'length)) then
          Sum  <= Sum + resize(MulResArr(to_integer(Sum_cnt)),Sum'length); -- signed Q10.10
          Sum_cnt <= Sum_cnt + to_unsigned(1,Sum_cnt'length);
          Calc_rdy(0) <= '1';
        elsif (Sum_cnt < to_unsigned(G_INPUTS-1,Arr_cnt'length)) then
          Sum  <= Sum + resize(MulResArr(to_integer(Sum_cnt)),Sum'length); -- signed Q10.10
          Sum_cnt <= Sum_cnt + to_unsigned(1,Sum_cnt'length);
          Calc_rdy(0) <= '0';
        else
          Sum     <= Sum;
          Sum_cnt <= Sum_cnt;
          Calc_rdy(0) <= Calc_rdy(0);
        end if;
        CalcBusy <= CalcBusy;
      else
        CalcBusy <= CalcBusy;
        Calc_rdy(0) <= '0';
        Sum  <= (others => '0');
        Sum_cnt <= (others => '0');
      end if;
        
    else -- wait for multiplication
      MulResArr        <= (others => (others => '0'));
      Arr_cnt          <= (others => '0');
      MulResultsStored <= '0';
      Sum           <= (others => '0');
      Sum_cnt          <= (others => '0');
      Calc_rdy(0) <= '0';
    end if;
    
    if (Calc_rdy(0) = '1') then -- convert to sigmoid function input [0 -> ( 2^16)-1]
      Sum_with_bias <= Sum + resize(signed(bias_latch(16-1 downto 1)),Sum'length);
      if (Sum_with_bias > SumMaxValuePos4) then
        Sum_saturated <= SumMaxValuePos4  - to_signed(1,s_SumRes'length); -- 7.99
      elsif (Sum_with_bias < SumMinValueNeg4) then
        Sum_saturated <= SumMinValueNeg4;
      else
        Sum_saturated <= Sum_with_bias;
      end if;
      s_SumRes <= Sum_saturated + SumMaxValuePos4;
      for ii in 0 to Calc_rdy'length-2 loop
        Calc_rdy(ii+1) <= Calc_rdy(ii);
      end loop;
    else
      s_SumRes <= s_SumRes;
    end if;
      if (Calc_rdy(Calc_rdy'length-1) = '1') then
        Sum_with_bias    <= (others => '0');
        Sum_saturated    <= (others => '0');
        Sum_cnt          <= (others => '0');
        Sum              <= (others => '0');
        MulResArr        <= (others => (others => '0'));
        Arr_cnt          <= (others => '0');
        MulResultsStored <= '0';
        CalcBusy         <= '0';
        Calc_rdy         <= (others => '0');
      end if;
      if (Calc_rdy(Calc_rdy'length-1) = '1') then
        o_Calc_rdy <= '1';
        ov_address <= std_logic_vector(std_logic_vector(s_SumRes(13-1 downto 0)) & std_logic_vector'(b"000")); --!* 0 to 7.999 ??? (ufix 3.13)
      else 
        o_Calc_rdy <= '0';
        ov_address <= (others => '0');
      end if;
    end if;
  end if;
end process;
end architecture;