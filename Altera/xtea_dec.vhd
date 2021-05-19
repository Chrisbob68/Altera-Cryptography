-- Library declarations
LIBRARY IEEE;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

-- Entity definition
ENTITY xtea_dec IS
PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				start				: IN  STD_LOGIC;	
				dec_enc_flag 	: IN  STD_LOGIC;

				key_word_in		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_word_in   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_word_out  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
				data_ready		: OUT STD_LOGIC
);
END ENTITY xtea_dec;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec IS
	
	-- XTEA Part 1 Decoding / Part 2 Encoding Component
	COMPONENT xtea_dec1_enc2 IS
	  PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			z1_inc  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0_inc 				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec1_enc2;
 
	-- XTEA Part 2 Decoding / Part 1 Encoding Component
	COMPONENT xtea_dec2_enc1 IS
	  PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 3337565984 (11000110111011110011011100100000) (32 bit)
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			y1_inc  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0_inc  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec2_enc1;
	
	--Intermediate Signals
	SIGNAL s_y0, s_y1, s_z0, s_z1 														: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
	SIGNAL s_y0_increment, s_y1_increment, s_z0_increment, s_z1_increment 	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); 
	
	--Processing Signals
	SIGNAL s_data_ready 	: STD_LOGIC := '0';
	SIGNAL s_sum 			: unsigned(31 DOWNTO 0):= (others => '0');
	constant total_cycles: unsigned(7 downto 0) := to_unsigned(32, 8);
	
	constant delta 			: unsigned (31 downto 0) := x"9E3779B9";
	constant sum_dec_init 	: unsigned (31 downto 0) := x"C6EF3720";
	constant sum_enc_init	: unsigned (31 downto 0) := (others => '0');
	
	--State Signals
	type t_state is (StartState, ProcessStateD1E2, ProcessStateD2E1, OutputState); -- Creates a type of signal known as t_state comprised of the states of the system.
	signal State, NextState : t_state;

BEGIN
	
	dec1 : xtea_dec1_enc2
	PORT MAP(
		reset_n     	=> reset_n,
		dec_enc_flag 	=> dec_enc_flag,
		sum 				=> s_sum,
		key 				=> key_word_in,
		y1     			=> s_y1,
		y0    			=> s_y0,
		z1_inc     		=> s_z1_increment,
		z0_inc  			=> s_z0_increment
	);
	 
	dec2 : xtea_dec2_enc1
	PORT MAP(
		reset_n     	=> reset_n,
		dec_enc_flag 	=> dec_enc_flag,
		sum 				=> s_sum,
		key 				=> key_word_in,
		z1     			=> s_z1,
		z0    			=> s_z0,
		y1_inc     		=> s_y0_increment,
		y0_inc  			=> s_y1_increment
	);

-- Process block to decode the next state of the system
Next_State_Decode : process (clk)
variable ns_iterator : unsigned(7 downto 0);
begin 
	if rising_edge(clk) then
		case (State) is
			when StartState =>
				ns_iterator := to_unsigned(0, 8);
            if start = '1' then 
					if dec_enc_flag = '0' then
						NextState <= ProcessStateD1E2;
					else NextState <= ProcessStateD2E1;
					end if;
            else Nextstate <= StartState;
            end if;
				
			when ProcessStateD1E2 => 
				if ns_iterator >= total_cycles*2 then 
                NextState <= StartState;
            else NextState <= ProcessStateD2E1;  
            end if;
			
			when ProcessStateD2E1 => 
				if ns_iterator >= total_cycles*2 then 
                NextState <= OutputState;
            else NextState <= ProcessStateD1E2;  
            end if;
				
			when OutputState => 
				if ns_iterator >= (total_cycles*2)+4 then 
                NextState <= StartState;
            else NextState <= OutputState;  
            end if;
				
			when others =>
		end case;
		ns_iterator := ns_iterator + 1;
	end if;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved.
Output_Decode : process (clk) 
begin
	if rising_edge(clk) then
		case (State) is
			when StartState =>
			
				s_z1 <= data_word_in(127 DOWNTO 96);
				s_y1 <= data_word_in(95 DOWNTO 64);
				s_z0 <= data_word_in(63 DOWNTO 32);
				s_y0 <= data_word_in(31 DOWNTO 0);
				
				data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				data_ready <= '0';
				
				if dec_enc_flag = '1' then
					s_sum <= sum_enc_init;
				else s_sum <= sum_dec_init;
				end if;
				
			when ProcessStateD1E2 => 
			
				s_z1 <= s_z1_increment;
				s_z0 <= s_z0_increment;

				data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				data_ready <= '0';
				
				if dec_enc_flag = '0' then
					s_sum <= s_sum - delta;
				end if;
			
			when ProcessStateD2E1 => 
				
				s_y1 <= s_y1_increment;
				s_y0 <= s_y0_increment;

				data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				data_ready <= '0';
				
				if dec_enc_flag = '1' then
					s_sum <= s_sum + delta;
				end if;
				
			when OutputState =>
			
				data_ready <= '1';
				data_word_out(127 DOWNTO 96) <= s_z1;
				data_word_out(95 DOWNTO 64) <= s_y1;
				data_word_out(63 DOWNTO 32) <= s_z0;
				data_word_out(31 DOWNTO 0) <= s_y0;
			
			when others =>
		end case;
	end if;
end process;

-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (Clk, reset_n) begin  
	if reset_n = '0' then
		 state <= StartState; -- Sets the default state of the system.
	elsif Clk' event and Clk = '1' then
		 State <= NextState;
	end if;
end process;
	 
end Behavioral;