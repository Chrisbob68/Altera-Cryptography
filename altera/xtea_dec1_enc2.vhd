-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; --Required for Shifts

-- Entity definition
ENTITY xtea_dec1_enc2 IS
PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			z1  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY xtea_dec1_enc2;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec1_enc2 IS

--Intermediate Signals
	SIGNAL z0_increment 	: unsigned(31 DOWNTO 0);
	SIGNAL z0_current 	: unsigned(31 DOWNTO 0);
	SIGNAL z1_increment 	: unsigned(31 DOWNTO 0);
	SIGNAL z1_current 	: unsigned(31 DOWNTO 0);
	
	SIGNAL y0_current 	: unsigned(31 DOWNTO 0);
	SIGNAL y1_current 	: unsigned(31 DOWNTO 0);
	
	SIGNAL key_index 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL key_calc 		: unsigned(31 DOWNTO 0);
	
BEGIN
	
	Reset_Process : process (reset_n) begin 

		if reset_n = '1' then
			z0 <= STD_LOGIC_VECTOR(z0_current);
			z1 <= STD_LOGIC_VECTOR(z1_current); 
			y0_current <= unsigned(y0);
			y1_current <= unsigned(y1);
		end if;
		
	end process;
	
	Output_Decode : process (dec_enc_flag,z0_increment,z1_increment,z0_current,z1_current) begin 

		if dec_enc_flag = '0' then
			z1_current <= z1_current + z1_increment;
			z0_current <= z0_current + z0_increment;
		else
			z1_current <= z1_current - z1_increment;
			z0_current <= z0_current - z0_increment;
		end if;
		
	end process;
	
	Key_index_Decode : process (sum) begin 

		key_index <= STD_LOGIC_VECTOR(sum(12 DOWNTO 11));
		
	end process;
	
	Key_Decode : process (sum, key, key_index, key_calc, y0_current, y1_current) begin 
		
		case (key_index) is
			when "00" =>
            key_calc <= sum + unsigned(key(127 DOWNTO 96));
				
			when "01" =>
            key_calc <= sum + unsigned(key(95 DOWNTO 64));
				
			when "10" =>
            key_calc <= sum + unsigned(key(63 DOWNTO 32));
				
			when "11" =>
            key_calc <= sum + unsigned(key(31 DOWNTO 0));
				
		end case;
		
		z1_increment <= ((shift_left(y1_current,4)) XOR (shift_right(y1_current,5))) XOR key_calc;
		z0_increment <= ((shift_left(y0_current,4)) XOR (shift_right(y0_current,5))) XOR key_calc;
		
	end process;
	
end Behavioral;