----------------------------------------------------------------------------------------------------
-- uart communication component
-- 1 start bit, 1 stop bit, no parity bit
----------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity uart_comm is
	generic (
		G_CyclesPerBit : integer := 50000000/115200; -- (clk_freq/baud_rate)
		G_FrameBitsNum : integer := 8
	);
	port (
		clk            : in std_logic;  -- 50 MHz
		rst            : in std_logic;
		enable         : in std_logic;
    send_data_start: in std_logic;
		send_data      : in std_logic_vector(G_FrameBitsNum-1 downto 0);
		send_buff_full : out std_logic; --uart is sending data
		rec_data       : out std_logic_vector(G_FrameBitsNum-1 downto 0);
		rec_data_valid : out std_logic; --data is valid and can be read on rec_data port
    rec_err        : out std_logic;
		tx_pin				 : out std_logic;
		rx_pin				 : in std_logic
	);
end entity;

architecture uart_comm_rtl of uart_comm is
--- TYPES
type t_uart is (IDLE, send_start_bit,send_frame, send_stop_bit, delay);
type r_uart is (IDLE, read_start ,read_frame, read_stop, delay);
--- transmitter related signals
signal transmit_state : t_uart:= IDLE;
signal u_TCycles_cnt 	: unsigned(16-1 downto 0) := (others => '0');
signal u_Tframe_cnt 	: unsigned(8-1 downto 0) := (others => '0');
signal send_data_Latched 		: std_logic_vector(send_data'length-1 downto 0) := (others => '0');
--- receiver related signals
signal rx_pin_r 		  : std_logic := '0';
signal rx_pin_r1		  : std_logic := '0';
signal rx_pin_r2		  : std_logic := '0';
signal receiv_state   : r_uart := IDLE;
signal u_RCycles_cnt  : unsigned(16-1 downto 0) := (others => '0');
signal u_Rframe_cnt   : unsigned(8-1 downto 0) := (others => '0');
signal receiver_frame : std_logic_vector(G_FrameBitsNum-1 downto 0) := (others => '0');
--- constants
constant C_CyclesPerBit 		: unsigned(16-1 downto 0) := to_unsigned(G_CyclesPerBit,16);
constant C_CyclesPer1_5_Bit : unsigned(16-1 downto 0) := to_unsigned(651,16);
begin
----------------------------------------------------------------------------------------------------
-- uart transmiter process
	transmit_proc: process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst='1') then
				transmit_state    <= IDLE;
				u_TCycles_cnt     <= (others => '0');
				send_data_Latched <= (others => '0');
				tx_pin            <= '1';
				send_buff_full    <= '0';
				u_Tframe_cnt      <= (others => '0');
			else
				if (enable = '1') then -- enable D flip flop input
					case transmit_state is
						when IDLE =>
							u_TCycles_cnt  <= (others => '0');
							u_Tframe_cnt   <= (others => '0');
							tx_pin <= '1'; 
							if (send_data_start = '1') then
								send_buff_full <= '1';
								transmit_state <= send_start_bit;
                send_data_Latched <= send_data;
							else
								send_buff_full <= '0';
								transmit_state <= IDLE;
							end if;
						when send_start_bit =>
							send_buff_full <= '1';
							tx_pin 				 <= '0';
							u_Tframe_cnt 	 <= (others => '0');
							if (u_TCycles_cnt = C_CyclesPerBit) then --5 
								u_TCycles_cnt   <= (others => '0');
								transmit_state <= send_frame;
							else
								u_TCycles_cnt   <= u_TCycles_cnt + to_unsigned(1,u_TCycles_cnt'length);
								transmit_state <= send_start_bit;
							end if;
						when send_frame => 
							send_buff_full <= '1';
							if (u_TCycles_cnt = C_CyclesPerBit ) then
								u_TCycles_cnt <= (others => '0');
								if (u_Tframe_cnt = (G_FrameBitsNum-1)) then
									u_Tframe_cnt    <= (others => '0');
									transmit_state <= send_stop_bit;
								else
									u_Tframe_cnt    <= u_Tframe_cnt + to_unsigned(1,u_Tframe_cnt'length);
									transmit_state <= send_frame;
								end if;
							else
								u_TCycles_cnt   <= u_TCycles_cnt + to_unsigned(1,u_TCycles_cnt'length);
								u_Tframe_cnt    <= u_Tframe_cnt;
								transmit_state <= send_frame;
							end if;
							tx_pin  <= send_data_Latched(to_integer(u_Tframe_cnt));
						when send_stop_bit => 
							send_buff_full <= '1';
							tx_pin <= '1';
							if (u_TCycles_cnt = C_CyclesPerBit) then --5 
								u_TCycles_cnt   <= (others => '0');
								transmit_state <= IDLE;
							else
								u_TCycles_cnt   <= u_TCycles_cnt + to_unsigned(1,u_TCycles_cnt'length);
								transmit_state <= send_stop_bit;
							end if;
						when others =>
							tx_pin <= '1';
							u_TCycles_cnt <= (others => '0');
							u_Tframe_cnt <= (others => '0');
							transmit_state <= IDLE;
							send_buff_full <= '0';
					end case;
				end if;
			end if;
		end if;
	end process;
----------------------------------------------------------------------------------------------------
-- uart receiver process
receive_proc: process(clk)
begin
	if rising_edge(clk) then
		if (rst = '1') then
			rec_data       <= (others => '0');
			rec_data_valid <= '0';
			receiv_state   <= IDLE;
			receiver_frame <= (others => '0');
			u_RCycles_cnt  <= (others => '0');
			u_Rframe_cnt   <= (others => '0');
			rx_pin_r  <= '0';
			rx_pin_r1 <= '0';
			rx_pin_r2 <= '0';
		else
			rx_pin_r  <= rx_pin;
			rx_pin_r1 <= rx_pin_r;
			rx_pin_r2 <= rx_pin_r1;

			case receiv_state is
				when IDLE =>
					if (rx_pin_r2 = '1' AND rx_pin_r1 = '0') then
						receiv_state <= read_start;
					else
						receiv_state <= IDLE;
					end if;		
					u_RCycles_cnt <= (others => '0');
					u_Rframe_cnt  <= (others => '0');
					rec_data_valid <= '0';
					receiver_frame <= (others => '0');
				when read_start => 
					rec_data_valid <= '0';
					if (u_RCycles_cnt < C_CyclesPer1_5_Bit) then
						u_RCycles_cnt  <= u_RCycles_cnt + to_unsigned(1,u_RCycles_cnt'length);
						receiv_state   <= read_start;
						receiver_frame <= receiver_frame;
						u_Rframe_cnt <= (others => '0');
					else
						u_RCycles_cnt <= (others => '0');
						receiv_state  <= read_frame;
						u_Rframe_cnt  <= u_Rframe_cnt + to_unsigned(1,u_Rframe_cnt'length);
 						receiver_frame(0) <= rx_pin_r1;
						receiver_frame(receiver_frame'length-1 downto 1) <= (others => '0');
					end if;
				when read_frame => 
					rec_data_valid <= '0';
					if (u_RCycles_cnt < C_CyclesPerBit) then
						u_RCycles_cnt <= u_RCycles_cnt + to_unsigned(1,u_RCycles_cnt'length);
						u_Rframe_cnt  <= u_Rframe_cnt;
						receiv_state  <= read_frame;
					else
						if (u_Rframe_cnt < G_FrameBitsNum-1 ) then
							u_RCycles_cnt <= (others => '0');
							u_Rframe_cnt  <= u_Rframe_cnt + to_unsigned(1,u_Rframe_cnt'length);
							receiv_state  <= read_frame;
						else
							u_RCycles_cnt <= (others => '0');
							u_Rframe_cnt  <= (others => '0');
							receiv_state  <= read_stop;
						end if;
						receiver_frame(to_integer(u_Rframe_cnt)) <= rx_pin_r1;
					end if;

				when read_stop => 
					if (u_RCycles_cnt < C_CyclesPerBit) then
						u_RCycles_cnt <= u_RCycles_cnt + to_unsigned(1,u_RCycles_cnt'length);
						rec_data_valid <= '0';
					else
						u_RCycles_cnt <= (others => '0');
						receiv_state  <= IDLE;
						if (rx_pin_r1 = '1') then
							rec_err        <= '0';
							rec_data_valid <= '1';
							rec_data       <= receiver_frame;
						else
							rec_err        <= '1';
							rec_data_valid <= '0';
							rec_data       <= (others => '0');
						end if;
					end if;
				when others =>
					rec_err <= '0';
					rec_data       <= (others => '0');
					rec_data_valid <= '0';
					receiv_state   <= IDLE;
					receiver_frame <= (others => '0');
					u_RCycles_cnt  <= (others => '0');
					u_Rframe_cnt   <= (others => '0');			
			end case;	
		end if;
	end if;
end process;

end architecture;
