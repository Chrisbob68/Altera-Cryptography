-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; --Required for Shifts

-- Entity definition
ENTITY xtea_dec1_enc2 IS
PORT(
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  STD_LOGIC_VECTOR(36 DOWNTO 0); -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
			
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
	SIGNAL y1_increment : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL y0_increment : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	type key is array (0 to 3) of STD_LOGIC_VECTOR(31 downto 0);
	
BEGIN

	key(0) <= key(127 DOWNTO 96);
	key(1) <= key(95 DOWNTO 64);
	key(2) <= key(63 DOWNTO 32);
	key(3) <= key(31 DOWNTO 0);

	y1_increment <= ((shift_left(y1,4) ** shift_right(y1,5)) + y1) ** (sum + key[shift_right(sum,(11 AND 3))]);
	y0_increment <= ((shift_left(y0,4) ** shift_right(y0,5)) + y0) ** (sum + key[shift_right(sum,(11 AND 3))]);

	if dec_enc_flag = '1' then
		z1 <= z1 + y1_increment;
		z0 <= z0 + y0_increment;
	else
		z1 <= z1 - y1_increment;
		z0 <= z0 - y0_increment;
	end if;
end Behavioral;