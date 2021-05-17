-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.all; --Required for Shifts

-- Entity definition
ENTITY xtea_dec2_enc1 IS
PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			y1  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY xtea_dec2_enc1;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec2_enc1 IS

--Intermediate Signals
	SIGNAL y0_increment 	: unsigned(31 DOWNTO 0);
	SIGNAL y0_current 	: unsigned(31 DOWNTO 0);
	SIGNAL y1_increment 	: unsigned(31 DOWNTO 0);
	SIGNAL y1_current 	: unsigned(31 DOWNTO 0);
	
	SIGNAL z0_current 	: unsigned(31 DOWNTO 0);
	SIGNAL z1_current 	: unsigned(31 DOWNTO 0);
	
	SIGNAL key_index 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL key_calc 		: unsigned(31 DOWNTO 0);
	
BEGIN
		
--		y1_increment <= ((shift_left(z1_current,4) ** shift_right(z1_current,5)) + z1_current) ** (sum + key_32(shift_right(sum,3)));
--		y0_increment <= ((shift_left(z0_current,4) ** shift_right(z0_current,5)) + z0_current) ** (sum + key_32(shift_right(sum,3)));
		
--		y1_increment <= STD_LOGIC_VECTOR((shift_left(unsigned(z1_current),4) ** STD_LOGIC_VECTOR(shift_right(unsigned(z1_current),5)) + z1_current)) ** STD_LOGIC_VECTOR(sum + key_32(sum AND 3));
--		y0_increment <= STD_LOGIC_VECTOR((shift_left(unsigned(z0_current),4) ** STD_LOGIC_VECTOR(shift_right(unsigned(z0_current),5)) + z0_current)) ** STD_LOGIC_VECTOR(sum + key_32(sum AND 3));

--		y1_increment <= ((z1 * 16) XOR (z1(31 DOWNTO 5) & '00000')) XOR (sum + key_32(key_index));
--		y0_increment <= ((z0 * 16) XOR (z0(31 DOWNTO 5) & '00000')) XOR (sum + key_32(key_index));
		
	
	
	Output_Decode : process (dec_enc_flag,y0_current,y1_current,y0_increment,y1_increment) begin 

		if dec_enc_flag = '1' then
			y1_current <= y1_current + y1_increment;
			y0_current <= y0_current + y0_increment;
		else
			y1_current <= y1_current - y1_increment;
			y0_current <= y0_current - y0_increment;
		end if;
		
	end process;
	
	Reset_Process : process (reset_n) begin 

		if reset_n = '1' then
			Y0 <= STD_LOGIC_VECTOR(Y0_current);
			Y1 <= STD_LOGIC_VECTOR(Y1_current); 
			Z0_current <= unsigned(Z0);
			Z1_current <= unsigned(Z1);
--			key_index <= "00";
--			key_calc <= to_unsigned(0,32);
		end if;
		
	end process;
	
	Key_Decode : process (sum, key_index, key, z1_current, z0_current, key_calc) begin 

		key_index <= STD_LOGIC_VECTOR(sum(12 DOWNTO 11));
		
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
		
		Y1_increment <= ((shift_left(Z1_current,4)) XOR (shift_right(Z1_current,5))) XOR key_calc;
		Y0_increment <= ((shift_left(Z0_current,4)) XOR (shift_right(Z0_current,5))) XOR key_calc;
		
	end process;
	
end Behavioral;