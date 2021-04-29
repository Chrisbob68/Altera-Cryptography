-- Library declarations
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity definition
ENTITY xtea IS
PORT(
            clk            		: IN  STD_LOGIC;
            reset_n        		: IN  STD_LOGIC;
				key_data_valid 		: IN  STD_LOGIC;
            data_word_in   		: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            key_word_in    		: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
				ciphertext_word_in  	: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            ciphertext_valid    	: IN  STD_LOGIC;
				
				data_word_out  		: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_ready     		: OUT STD_LOGIC;
				cyphertext_word_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            cyphertext_ready     : OUT STD_LOGIC
        );
END ENTITY xtea;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea IS

    -- XTEA Subkey Encoding Component
    COMPONENT xtea_subkey_calc_enc IS
        PORT(
            clk            : IN  STD_LOGIC;
            key_valid 		: IN  STD_LOGIC;
            key_word_in    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            key_word_out  	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT xtea_subkey_calc_enc;
	 
	 -- XTEA Subkey Decoding  Component
    COMPONENT xtea_subkey_calc_dec IS
        PORT(
            clk            : IN  STD_LOGIC;
            key_valid 		: IN  STD_LOGIC;
            key_word_in    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            key_word_out  	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT xtea_subkey_calc_dec;
	 
	 -- XTEA Encoding  Component
    COMPONENT xtea_enc IS
        PORT(
            clk                 : IN  STD_LOGIC;
            data_word_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_valid          : IN  STD_LOGIC;
            key_word_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_word_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_ready          : OUT STD_LOGIC
        );
    END COMPONENT xtea_enc;
	 
	 	 -- XTEA Decoding  Component
    COMPONENT xtea_dec IS
        PORT(
            clk                 : IN  STD_LOGIC;
            data_word_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_valid          : IN  STD_LOGIC;
            key_word_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_word_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_ready          : OUT STD_LOGIC
        );
    END COMPONENT xtea_dec;

    
	 -- Clock period constant
    CONSTANT clk_period : TIME    := 10 ns;

    -- Clock and reset signals
	 SIGNAL s_clk                    : STD_LOGIC;
    SIGNAL s_reset                  : STD_LOGIC;
	 
    -- Key/data input interface signals
    SIGNAL s_key_data_valid       : STD_LOGIC;
    SIGNAL s_input_data           : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_input_key            : STD_LOGIC_VECTOR(31 DOWNTO 0);
	 
	 -- Intermediate Processing signals
	 SIGNAL s_enc_key_word_out 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	 SIGNAL s_dec_key_word_out 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	 
    -- Data output interface signals
    SIGNAL s_output_data          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_output_data_flag     : STD_LOGIC;

BEGIN

    -- Device under test instantiation
    subkey_calc_enc : xtea_subkey_calc_enc
    PORT MAP(
        clk             => s_clk,
        reset_n         => s_reset,
        key_word_in     => s_key_word_in,
        key_valid       => s_key_valid,
        key_word_out 	=> s_enc_key_word_out
    );
	 
	 subkey_calc_dec : xtea_subkey_calc_dec
    PORT MAP(
        clk             => s_clk,
        reset_n         => s_reset,
        key_word_in     => s_key_word_in,
        key_valid       => s_key_valid,
        key_word_out 	=> s_dec_key_word_out
    );
	 
	 	 enc : xtea_enc
    PORT MAP(
        clk            => s_clk,
        reset_n        => s_reset,
        data_word_in   => s_data_word_in,
        data_valid     => s_data_valid,
        key_word_in    => s_enc_key_word_out,
		  data_ready     => s_cyphertext_ready,
        data_word_out  => s_cyphertext_word_out
    );
	 
	 	 dec : xtea_dec
    PORT MAP(
        clk            => s_clk,
        reset_n        => s_reset,
        data_word_in   => s_ciphertext_word_in,
        data_valid     => s_ciphertext_valid,
        key_word_in    => s_dec_key_word_out,
		  data_ready     => s_data_ready,
        data_word_out  => s_data_word_out
    );
	 
	 
-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (s_clk)
        begin  
        if s_reset = '1' then         
            
        elsif s_clk' event and s_clk = '1' then
            
        end if;
end process;

end Behavioral;