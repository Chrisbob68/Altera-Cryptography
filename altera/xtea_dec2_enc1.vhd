-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; --Required for Shifts

-- Entity definition
ENTITY xtea_dec2_enc1 IS
PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0);
			
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			y1_inc  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0_inc  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY xtea_dec2_enc1;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec2_enc1 IS

--Intermediate Signals
	SIGNAL y0_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y0_current 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y1_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y1_current 	: unsigned(31 DOWNTO 0) := (others => '0');
	
	SIGNAL key_index 		: STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');
	SIGNAL key_calc 		: unsigned(31 DOWNTO 0) := (others => '0');
	
BEGIN
		
	Output_Decode : process (reset_n, dec_enc_flag,y0_current,y1_current,y0_increment,y1_increment) begin 

		if reset_n = '0' then
			y0_inc <= (others => '0');
			y1_inc <= (others => '0');
		elsif dec_enc_flag = '1' then
			y1_inc <= STD_LOGIC_VECTOR(y1_current + y1_increment);
			y0_inc <= STD_LOGIC_VECTOR(y0_current + y0_increment);
		else
			y1_inc <= STD_LOGIC_VECTOR(y1_current - y1_increment);
			y0_inc <= STD_LOGIC_VECTOR(y0_current - y0_increment);
		end if;
		
	end process;
	
	Key_index_Decode : process (sum) begin 

		key_index <= STD_LOGIC_VECTOR(sum(1 DOWNTO 0));
		
	end process;
	
	Key_Decode : process (sum, key_index, key, z1, z0, key_calc) begin 
		
		case (key_index) is
			when "00" =>
            key_calc <= sum + unsigned(key(127 DOWNTO 96));
				
			when "01" =>
            key_calc <= sum + unsigned(key(95 DOWNTO 64));
				
			when "10" =>
            key_calc <= sum + unsigned(key(63 DOWNTO 32));
				
			when "11" =>
            key_calc <= sum + unsigned(key(31 DOWNTO 0));
			when others =>
	
		end case;
		
		Y1_increment <= ((shift_left(unsigned(z1),4) + unsigned(z1)) XOR (shift_right(unsigned(z1),5))) XOR key_calc;
		Y0_increment <= ((shift_left(unsigned(z0),4) + unsigned(z0)) XOR (shift_right(unsigned(z0),5))) XOR key_calc;
		
	end process;
	
end Behavioral;