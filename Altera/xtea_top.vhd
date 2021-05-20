-- Library declarations
LIBRARY IEEE;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

-- Entity definition
ENTITY xtea_top IS
PORT(
				
				clk            : IN  STD_LOGIC;
            reset_n        : IN  STD_LOGIC;
            encryption     : IN  STD_LOGIC;
            key_data_valid : IN  STD_LOGIC;
            data_word_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            key_word_in    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_word_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_ready     : OUT STD_LOGIC
		);
END ENTITY xtea_top;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_top IS
	 
	 -- XTEA Encoding  Component
--    COMPONENT xtea_enc IS
--        PORT(
--            clk                 : IN  STD_LOGIC;
--				reset_n				  : IN  STD_LOGIC;
--            data_word_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_valid          : IN  STD_LOGIC;
--            key_word_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_word_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_ready          : OUT STD_LOGIC
--        );
--    END COMPONENT xtea_enc;
	 
	 	 -- XTEA Decoding  Component
    COMPONENT xtea_dec IS
        PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				start				: IN  STD_LOGIC;
				dec_enc_flag 	: IN  STD_LOGIC;

				key_word_in		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_word_in   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_word_out  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
				data_ready 		: OUT STD_LOGIC
        );
    END COMPONENT xtea_dec;

	-- Clock and reset signals
	SIGNAL s_clk                    	: STD_LOGIC;
	SIGNAL s_reset_n                 : STD_LOGIC;
 
    -- Key/data input interface signals
	SIGNAL s_start       				: STD_LOGIC := '0';
	SIGNAL s_data_word_in         	: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');
	SIGNAL s_key_word_in          	: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');

	-- Data output interface signals
	SIGNAL s_data_word_out       		: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');
	SIGNAL s_data_ready     			: STD_LOGIC := '0';
	
	-- State Signals
	type t_state is (idle, keydatain1, keydatain2, keydatain3, encdec, output1, output2, output3, output4); -- Creates a type of signal known as t_state comprised of the states of the system.
	signal State, NextState : t_state;
	
BEGIN
	
	s_clk <= clk;
	s_reset_n <= reset_n;
	 
--	enc : xtea_enc PORT MAP(
--		clk            => s_clk,
--		reset_n        => s_reset_n,
--		key_data_valid => s_key_data_valid,
--		key_word_in    => s_key_word_in,
--		data_word_in   => s_data_word_in,
--		data_word_out  => s_data_word_out
--    );
	 
	dec : xtea_dec PORT MAP(
		clk            => s_clk,
		reset_n        => s_reset_n,
		start 			=> s_start,
		dec_enc_flag 	=> encryption,
		key_word_in    => s_key_word_in,
		data_word_in   => s_data_word_in,
		data_word_out  => s_data_word_out,
		data_ready 		=> s_data_ready
		);


-- Process block to decode the next state of the system
Next_State_Decode : process (clk, State,key_data_valid, s_data_ready) begin
 
		case (State) is
		
			when idle =>
			
            if key_data_valid = '1' then 
					NextState <= keydatain1;
				else NextState <= idle;
				end if;

			when keydatain1 => 
				 NextState <= keydatain2;
					 
			when keydatain2 => 
				 NextState <= keydatain3;
					 
			when keydatain3 => 
				 NextState <= encdec;
			
			when encdec => 
			
				if s_data_ready = '1' then 
                NextState <= output1;
            else NextState <= encdec;  
            end if;
				
			when output1 =>

				NextState <= output2;
				
			when output2 =>

				NextState <= output3;
				
			when output3 =>

				NextState <= output4;
				
			when output4 =>

				NextState <= idle;

		end case;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved.
Output_Decode : process (State, key_data_valid, key_word_in, data_word_in, s_data_word_out) begin
		case (State) is
		
			when idle =>

				s_start <= '0';
				data_ready <= '0';
				data_word_out <= (others => '0');
				
				if key_data_valid = '1' then 
				
					s_key_word_in(31 DOWNTO 0) <= key_word_in;
					s_data_word_in(31 DOWNTO 0) <= data_word_in;
					
				end if;
				
			when keydatain1 => 
				
				s_start <= '0';
				data_ready <= '0';
				data_word_out <= (others => '0');
				
				s_key_word_in(63 DOWNTO 32) <= key_word_in;
				s_data_word_in(63 DOWNTO 32) <= data_word_in;
				
			when keydatain2 => 
				
				s_start <= '0';
				data_ready <= '0';
				data_word_out <= (others => '0');
				
				s_key_word_in(95 DOWNTO 64) <= key_word_in;
				s_data_word_in(95 DOWNTO 64) <= data_word_in;
				
			when keydatain3 => 
				
				s_start <= '0';
				data_ready <= '0';
				data_word_out <= (others => '0');
				
				s_key_word_in(127 DOWNTO 96) <= key_word_in;
				s_data_word_in(127 DOWNTO 96) <= data_word_in;
				
			when encdec => 
			
				s_start <= '1';
				data_ready <= '0';
				data_word_out <= (others => '0');
				
			when output1 =>
				
				s_start <= '0';
				data_word_out <= s_data_word_out(31 DOWNTO 0);
				
			when output2 =>
				
				s_start <= '0';
				data_word_out <= s_data_word_out(63 DOWNTO 32);
			
			when output3 =>
				
				s_start <= '0';
				data_word_out <= s_data_word_out(95 DOWNTO 64);
				
			when output4 =>
				
				s_start <= '0';
				data_word_out <= s_data_word_out(127 DOWNTO 96);
				data_ready <= '1';
				
		end case;
end process;

-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (Clk, reset_n) begin  
	if reset_n = '0' then
		 state <= idle; -- Sets the default state of the system.
	elsif Clk' event and Clk = '1' then
		 State <= NextState;
	end if;
end process;
	 
end Behavioral;