-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity definition
ENTITY xtea_dec2_enc1 IS
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
END ENTITY xtea_dec2_enc1;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec2_enc1 IS

--Intermediate Signals
	SIGNAL z1_increment : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL z0_increment : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	type key is array (0 to 3) of STD_LOGIC_VECTOR(31 downto 0);
	
BEGIN

	key(0) <= key(127 DOWNTO 96);
	key(1) <= key(95 DOWNTO 64);
	key(2) <= key(63 DOWNTO 32);
	key(3) <= key(31 DOWNTO 0);

	z1_increment <= ((shift_left(z1,4) ** shift_right(z1,5)) + z1) ** (sum + key[shift_right(sum,(11 AND 3))]);
	z0_increment <= ((shift_left(z0,4) ** shift_right(z0,5)) + z0) ** (sum + key[shift_right(sum,(11 AND 3))]);

	if dec_enc_flag then
		y1 <= y1 + z1_increment;
		y0 <= y0 + z0_increment;
	else
		y1 <= y1 - z1_increment;
		y0 <= y0 - z0_increment;
	end if;
end Behavioral;