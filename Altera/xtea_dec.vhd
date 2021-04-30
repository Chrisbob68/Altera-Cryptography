-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Entity definition
ENTITY xtea_enc IS
PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				key_data_valid	: IN  STD_LOGIC;	

				key_word_in		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_word_in   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_word_out  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
);
END ENTITY xtea_enc;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_enc IS

	-- XTEA Part 1 Decoding / Part 2 Encoding Component
	COMPONENT xtea_dec1_enc2 IS
	  PORT(
			clk            : IN  STD_LOGIC;
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			iterator			: IN  STD_LOGIC_VECTOR(4 DOWNTO 0); -- Max number stored is 31 : 11111 ( 5 Bit )
			sum				: IN  STD_LOGIC_VECTOR(36 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z1  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec1_enc2;
 
	-- XTEA Part 2 Decoding / Part 1 Encoding Component
	COMPONENT xtea_dec2_enc1 IS
	  PORT(
			clk            : IN  STD_LOGIC;
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			iterator			: IN  STD_LOGIC_VECTOR(4 DOWNTO 0); -- Max number stored is 31 : 11111 ( 5 Bit )
			sum				: IN  STD_LOGIC_VECTOR(36 DOWNTO 0); -- Max number stored is : 3337565984 (11000110111011110011011100100000) (32 bit)
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
	SIGNAL s_sum 			: STD_LOGIC_VECTOR(36 DOWNTO 0);
	SIGNAL s_iterator 	: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL s_delta 		: STD_LOGIC_VECTOR(36 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(2654435769, 37));--0x9E3779B9
	
	--State Signals
	type t_state is (StartState, FinishState, ProcessState); -- Creates a type of signal known as t_state comprised of the states of the system.
	signal State, NextState : t_state;

BEGIN

	 dec1 : xtea_dec1_enc2
    PORT MAP(
        clk          => clk,
        reset_n     	=> reset_n,
        dec_enc_flag => '1',
		  iterator   	=> s_iterator,
		  sum 			=> s_sum,
        z1     		=> s_z1,
        z0    			=> s_z0,
		  y1     		=> s_y1_increment,
        y0  			=> s_y0_increment
    );
	 
	 dec2 : xtea_dec2_enc1
    PORT MAP(
        clk          => clk,
        reset_n     	=> reset_n,
		  dec_enc_flag => '1',
        iterator   	=> s_iterator,
		  sum 			=> s_sum,
        y1     		=> s_y1,
        y0    			=> s_y0,
		  z1     		=> s_z0_increment,
        z0  			=> s_z1_increment
    );

-- Process block to decode the next state of the system
Next_State_Decode : process (Clk) 
	begin --, BTNR, BTNC, BTNU

		case (State) is
			when StartState =>
            if key_data_valid = '1' then 
                NextState <= ProcessState;
            else Nextstate <= StartState;
            end if;
				
			when ProcessState => 
				if s_data_ready = '1' then 
                NextState <= FinishState;
            else NextState <= ProcessState;  
            end if;

			when FinishState => 
				NextState <= StartState;
	end case;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved.
Output_Decode : process (clk) begin
	case (State) is
		when StartState =>
		
			s_sum <= STD_LOGIC_VECTOR(to_unsigned(3337565984, 37));
			s_iterator <= STD_LOGIC_VECTOR(to_unsigned(0, 5));
			
			s_z1 <= data_word_in(127 DOWNTO 96);
			s_y1 <= data_word_in(95 DOWNTO 64);
			s_z0 <= data_word_in(63 DOWNTO 32);
			s_y0 <= data_word_in(31 DOWNTO 0);
			
			data_word_out(127 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(0, 128));
			
			
		When ProcessState => 
			
			s_z1 <= s_z1_increment;
			s_z0 <= s_z0_increment;
			s_y1 <= s_y1_increment;
			s_y0 <= s_y0_increment;
			
			s_iterator <= s_iterator + 1;
			s_sum <= s_sum - s_delta;
			
			
			
		when FinishState =>
			
			data_word_out(127 DOWNTO 96) <= s_z1;
			data_word_out(95 DOWNTO 64) <= s_y1;
			data_word_out(63 DOWNTO 32) <= s_z0;
			data_word_out(31 DOWNTO 0) <= s_y0;
			
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