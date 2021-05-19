-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.all; --Required for UNSIGNED conversion

ENTITY xtea_sum IS
  PORT(
		trigger 			: IN  STD_LOGIC;
		reset_n			: IN  STD_LOGIC;
		dec_enc_flag 	: IN  STD_LOGIC;
		sum				: OUT  unsigned(31 DOWNTO 0) -- Max number stored is : 84941944608 (0x9E3779B9 * 32) (1001111000110111011110011011100100000) (37 bit)
  );
END ENTITY xtea_sum;
	
ARCHITECTURE Behavioral OF xtea_sum IS

	constant delta 	: unsigned (31 downto 0) := x"9E3779B9";
	constant dec_init : unsigned (31 downto 0) := x"C6EF3720";
	constant enc_init	: unsigned (31 downto 0) := (others => '0');
	SIGNAL s_sum 		: unsigned(31 DOWNTO 0);

BEGIN

	Reset_Process : process (reset_n, dec_enc_flag) begin 

			if reset_n = '0' then				
				if dec_enc_flag = '1' then
					s_sum <= enc_init;
				else
					s_sum <= dec_init;
				end if;
			end if;
			
	end process;

	Trigger_Process : process (trigger) begin  
		
		if rising_edge(trigger) then
			if dec_enc_flag = '1' then
				sum <= s_sum - delta;
			else
				sum <= s_sum + delta;
			end if;
		end if;
	end process;
end Behavioral;