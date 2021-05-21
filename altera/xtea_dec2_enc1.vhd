--################################################################################################
--## Developer: Chris Holland (B726822)                                                  			##
--##                                                                                    			##
--## Design name: xtea                                                                  			##
--## Module name: xtea_dec2_enc1 - Encoding and Decoding Module                            		##
--## Target devices: Altera DE1-SOC Prototyping Board                                   			##
--## Tool versions: Quartus Prime Lite Edition 19.1, ModelSim Intel FPGA Starter Edition 10.5b  ##
--##                                                                                    			##
--## Description: With the given inputs from xtea_enc_dec this module computes the expected		##
--## 					increment for a given stage of the xtea algorithm, allowing xtea_enc_dec		##
--## 					to implement the xtea algorithm simply in a single signal update.					##
--## 					This module implements the second step of decoding, which is the same as the	##
--##					first step of encoding. Combining these modules together saves space on the	##
--##					FPGA.																									##
--##                                                                                    			##
--## Dependencies: xtea_top.vhd, xtea_enc_dec.vhd                                       			##
--################################################################################################

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
			y1					: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0					: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			y1_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY xtea_dec2_enc1;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_dec2_enc1 IS

--Intermediate Signals
	SIGNAL y0_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y0u 				: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y1_increment 	: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL y1u 				: unsigned(31 DOWNTO 0) := (others => '0');
	
	SIGNAL z0u				: unsigned(31 DOWNTO 0) := (others => '0');
	SIGNAL z1u				: unsigned(31 DOWNTO 0) := (others => '0');
	
BEGIN
		
	-- Begin by permanantly setting an unsigned version y0,y1,z0,z1 for mathematical operations
	y0u <= unsigned(y0);
	y1u <= unsigned(y1);
	z0u <= unsigned(z0);
	z1u <= unsigned(z1);
		
-- Process to handle the internal signals, and select the correct output based off those signals.
Output_Decode : process (reset_n, dec_enc_flag,y0u,y1u,y0_increment,y1_increment) begin 

	-- If reset is triggered, reset the outputs to 0.
	if reset_n = '0' then
		y0_new <= (others => '0');
		y1_new <= (others => '0');		
	-- If reset is not triggered, then check the mode of the system, if in encoding, increment the z0 and z1 value
	-- If in decoding, then decrement the z0 and z1 values.
	elsif dec_enc_flag = '1' then
		y1_new <= STD_LOGIC_VECTOR(y1u + y1_increment);
		y0_new <= STD_LOGIC_VECTOR(y0u + y0_increment);
	else
		y1_new <= STD_LOGIC_VECTOR(y1u - y1_increment);
		y0_new <= STD_LOGIC_VECTOR(y0u - y0_increment);
	end if;
	
end process;

-- Process to set the internal xtea signals based off the inputs given to the component.
-- Process needs to be simulated when sum, key, z0u and z1u are modified.
Key_Decode : process (sum, key, z1u, z0u) 
-- Keycalc Unsigned variable to hold the subkey calculation, simplyfying the increment line of code significantly.
variable key_calc : unsigned(31 DOWNTO 0) := (others => '0');
begin 
	
	-- As per the XTEA algorithm, selecting the 1st and 2nd bits of the algorithm and using them to select which
	--	word of the key to use for this iteration of the algorithm.
	case (sum(1 DOWNTO 0)) is
		when "00" =>				
			-- Assign the addition of sum and the selected key to the keycalc variable, depeding on the 1st and 2nd bits of the sum.
			-- keycalc = sum + *k[sum & 3];
			key_calc := sum + unsigned(key(127 DOWNTO 96));
			
		when "01" =>
			key_calc := sum + unsigned(key(95 DOWNTO 64));
			
		when "10" =>
			key_calc := sum + unsigned(key(63 DOWNTO 32));
			
		when "11" =>
			key_calc := sum + unsigned(key(31 DOWNTO 0));
		when others =>

	end case;
	
	-- Perform the XTEA algorithm to work out the amount to icrement z1 and z0 by based on the inputs.
	-- y1  -= ((z1 << 4 ^ z1 >> 5) + z1) ^ keycalc;
	y1_increment <= ((shift_left(z1u,4) XOR shift_right(z1u,5)) + z1u) XOR key_calc;
	y0_increment <= ((shift_left(z0u,4) XOR shift_right(z0u,5)) + z0u) XOR key_calc;
	
end process;
	
end Behavioral;