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

	-- Sum Decoding Component
	COMPONENT xtea_sum IS
	  PORT(
			trigger			: IN  STD_LOGIC;
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: OUT unsigned(31 DOWNTO 0) -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
	  );
	END COMPONENT xtea_sum;
	
	-- XTEA Part 1 Decoding / Part 2 Encoding Component
	COMPONENT xtea_dec1_enc2 IS
	  PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z1  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec1_enc2;
 
	-- XTEA Part 2 Decoding / Part 1 Encoding Component
	COMPONENT xtea_dec2_enc1 IS
	  PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 3337565984 (11000110111011110011011100100000) (32 bit)
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y1  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec2_enc1;
	
	--Intermediate Signals
	SIGNAL s_y0, s_y1, s_z0, s_z1 														: STD_LOGIC_VECTOR(31 DOWNTO 0); -- Vectors to hold
	SIGNAL s_y0_increment, s_y1_increment, s_z0_increment, s_z1_increment 	: STD_LOGIC_VECTOR(31 DOWNTO 0); 
	
	--Processing Signals
	SIGNAL s_data_ready 	: STD_LOGIC;
	SIGNAL s_trigger 		: STD_LOGIC;
	SIGNAL s_sum 			: unsigned(31 DOWNTO 0);
	SIGNAL s_iterator 	: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL s_delta 		: STD_LOGIC_VECTOR(31 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(2654435769, 32));--0x9E3779B9
	
	--State Signals
	type t_state is (StartState, ProcessStateD1E2, ProcessStateD2E1); -- Creates a type of signal known as t_state comprised of the states of the system.
	signal State, NextState : t_state;

BEGIN

	sumblock : xtea_sum
	PORT MAP(
			trigger			=> s_trigger,
			reset_n			=> reset_n,
			dec_enc_flag 	=> dec_enc_flag,
			sum				=> s_sum
	);
			
	 dec1 : xtea_dec1_enc2
    PORT MAP(
        reset_n     	=> reset_n,
        dec_enc_flag => dec_enc_flag,
		  sum 			=> s_sum,
        y1     		=> s_y1,
        y0    			=> s_y0,
		  z1     		=> s_z1_increment,
        z0  			=> s_z0_increment
    );
	 
	 dec2 : xtea_dec2_enc1
    PORT MAP(
        reset_n     	=> reset_n,
		  dec_enc_flag => dec_enc_flag,
		  sum 			=> s_sum,
        z1     		=> s_z1,
        z0    			=> s_z0,
		  y1     		=> s_y0_increment,
        y0  			=> s_y1_increment
    );

-- Process block to decode the next state of the system
Next_State_Decode : process (State, start, s_iterator, dec_enc_flag) begin 
		case (State) is
			when StartState =>
            if start = '1' then 
					if dec_enc_flag = '0' then
						NextState <= ProcessStateD1E2;
					else NextState <= ProcessStateD2E1;
					end if;
            else Nextstate <= StartState;
            end if;
				
			when ProcessStateD1E2 => 
				if s_iterator = "10000" then 
                NextState <= StartState;
            else NextState <= ProcessStateD2E1;  
            end if;
			
			when ProcessStateD2E1 => 
				if s_iterator = "10000" then 
                NextState <= StartState;
            else NextState <= ProcessStateD1E2;  
            end if;
			
		end case;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved.
Output_Decode : process (State, s_iterator, s_z1, s_z0, s_y1, s_y0, data_word_in, s_y1_increment, s_y0_increment, s_z0_increment, s_z1_increment, s_trigger) begin
		case (State) is
			when StartState =>
			
				s_iterator <= STD_LOGIC_VECTOR(to_unsigned(0, 5));
				
				s_z1 <= data_word_in(127 DOWNTO 96);
				s_y1 <= data_word_in(95 DOWNTO 64);
				s_z0 <= data_word_in(63 DOWNTO 32);
				s_y0 <= data_word_in(31 DOWNTO 0);
				
				data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				
				s_trigger <= '0';
				
			when ProcessStateD1E2 => 
			
				s_z1 <= s_z1_increment;
				s_z0 <= s_z0_increment;
						
				if dec_enc_flag = '1' then
					s_iterator <= s_iterator + 1;
					s_trigger <= '0';
				else s_trigger <= '1';
				end if;
				
				if s_iterator = "10000" then 
					data_word_out(127 DOWNTO 96) <= s_z1;
					data_word_out(95 DOWNTO 64) <= s_y1;
					data_word_out(63 DOWNTO 32) <= s_z0;
					data_word_out(31 DOWNTO 0) <= s_y0;
				else
					data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				end if;
			
			when ProcessStateD2E1 => 
				
				s_y1 <= s_y1_increment;
				s_y0 <= s_y0_increment;
				
				if dec_enc_flag = '0' then
					s_iterator <= s_iterator + 1;	
					s_trigger <= '0';
				else s_trigger <= '1';
				end if;
				
				if s_iterator = "10000" then 
					
					data_word_out(127 DOWNTO 96) <= s_z1;
					data_word_out(95 DOWNTO 64) <= s_y1;
					data_word_out(63 DOWNTO 32) <= s_z0;
					data_word_out(31 DOWNTO 0) <= s_y0;
				else
					data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
				end if;
		end case;
end process;

-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (Clk, reset_n) begin  
	if reset_n = '1' then
		 state <= StartState; -- Sets the default state of the system.
	elsif Clk' event and Clk = '1' then
		 State <= NextState;
	end if;
end process;
	 
end Behavioral;