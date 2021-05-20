-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; --Required for Shifts

-- Entity definition
ENTITY xtea_dec1_enc2 IS
PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0);
			
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			z1_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY xtea_dec1_enc2;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec1_enc2 IS

--Intermediate Signals
	SIGNAL z0_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL z0u 				: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL z1_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL z1u 				: unsigned(31 DOWNTO 0) := (others => '0');
	
	SIGNAL y0u				: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y1u				: unsigned(31 DOWNTO 0) := (others => '0');
	
BEGIN

	y0u <= unsigned(y0);
	y1u <= unsigned(y1);
	z0u <= unsigned(z0);
	z1u <= unsigned(z1);

	Output_Decode : process (reset_n, dec_enc_flag,z0_increment,z1_increment,z0u,z1u) begin 
		
		if reset_n = '0' then
			z0_new <= (others => '0');
			z1_new <= (others => '0');
		elsif dec_enc_flag = '1' then
			z1_new <= STD_LOGIC_VECTOR(z1u + z1_increment);
			z0_new <= STD_LOGIC_VECTOR(z0u + z0_increment);
		else
			z1_new <= STD_LOGIC_VECTOR(z1u - z1_increment);
			z0_new <= STD_LOGIC_VECTOR(z0u - z0_increment);
		end if;
		
	end process;
	
	Key_Decode : process (sum, key, y0u, y1u) 
	variable key_calc : unsigned(31 DOWNTO 0) := (others => '0');
	begin 
		
		case (sum(12 DOWNTO 11)) is
			when "00" =>
            key_calc := sum + unsigned(key(127 DOWNTO 96));
				
			when "01" =>
            key_calc := sum + unsigned(key(95 DOWNTO 64));
				
			when "10" =>
            key_calc := sum + unsigned(key(63 DOWNTO 32));
				
			when "11" =>
            key_calc := sum + unsigned(key(31 DOWNTO 0));
			when others =>

		end case;
		
		z1_increment <= ((shift_left(y1u,4) XOR shift_right(y1u,5)) + y1u) XOR key_calc;
		z0_increment <= ((shift_left(y0u,4) XOR shift_right(y0u,5)) + y0u) XOR key_calc;
		
	end process;
	
end Behavioral;