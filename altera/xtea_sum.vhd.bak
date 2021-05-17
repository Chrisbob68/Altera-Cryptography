-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity definition
ENTITY xtea_top IS
PORT(
            clk            		: IN  STD_LOGIC;
            reset_n        		: IN  STD_LOGIC;
				key_data_valid 		: IN  STD_LOGIC;
            data_word_in   		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            key_word_in    		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
				data_word_out  		: OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_ready     		: OUT STD_LOGIC
		);
END ENTITY xtea_top;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_top IS
	 
	 -- XTEA Encoding  Component
--    COMPONENT xtea_enc IS
--        PORT(
--            clk                 : IN  STD_LOGIC;
--				reset_n				  : IN  STD_LOGIC;
--            data_word_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_valid          : IN  STD_LOGIC;
--            key_word_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_word_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--            data_ready          : OUT STD_LOGIC
--        );
--    END COMPONENT xtea_enc;
	 
	 	 -- XTEA Decoding  Component
    COMPONENT xtea_dec IS
        PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				key_data_valid	: IN  STD_LOGIC;	

				key_word_in		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_word_in   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_word_out  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
        );
    END COMPONENT xtea_dec;
	
	-- Clock period constant
	CONSTANT clk_period 					: TIME := 10 ns;

	-- Clock and reset signals
	SIGNAL s_clk                    	: STD_LOGIC;
	SIGNAL s_reset_n                 : STD_LOGIC;
 
    -- Key/data input interface signals
	SIGNAL s_key_data_valid       	: STD_LOGIC;
	SIGNAL s_data_word_in         	: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL s_key_word_in          	: STD_LOGIC_VECTOR(127 DOWNTO 0);

	-- Data output interface signals
	SIGNAL s_data_word_out       		: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL s_data_ready     			: STD_LOGIC;

BEGIN
	
	s_clk <= clk;
	s_reset_n <= reset_n;
	s_key_data_valid <= key_data_valid;
	s_data_word_in <= data_word_in;
	s_key_word_in <= key_word_in;
	
	data_word_out <= s_data_word_out;
	data_ready <= s_data_ready;
	 
--	enc : xtea_enc PORT MAP(
--		clk            => s_clk,
--		reset_n        => s_reset_n,
--		key_data_valid => s_key_data_valid,
--		key_word_in    => s_key_word_in,
--		data_word_in   => s_data_word_in,
--		data_word_out  => s_data_word_out
--    );
	 
	dec : xtea_dec PORT MAP(
		clk            => s_clk,
		reset_n        => s_reset_n,
		key_data_valid => s_key_data_valid,
		key_word_in    => s_key_word_in,
		data_word_in   => s_data_word_in,
		data_word_out  => s_data_word_out
		);


end Behavioral;