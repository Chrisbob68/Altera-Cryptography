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

	SIGNAL delta 	: unsigned(31 DOWNTO 0);
	SIGNAL s_sum 	: unsigned(31 DOWNTO 0);

BEGIN

	Reset_Process : process (reset_n) begin 

			if reset_n = '1' then
				
				 delta <= to_unsigned(2654435769, 32);--0x9E3779B9
				
				if dec_enc_flag = '1' then
					s_sum <= to_unsigned(3337565984,32);
				else
					s_sum <= to_unsigned(0,32);
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