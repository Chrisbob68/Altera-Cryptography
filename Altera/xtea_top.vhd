--################################################################################################
--## Developer: Chris Holland (B726822)                                                  			##
--##                                                                                    			##
--## Design name: xtea                                                                  			##
--## Module name: xtea_top - Top		                                                    			##
--## Target devices: Altera DE1-SOC Prototyping Board                                   			##
--## Tool versions: Quartus Prime Lite Edition 19.1, ModelSim Intel FPGA Starter Edition 10.5b  ##
--##                                                                                    			##
--## Description: XTEA Algorithm Top Level Interface, Handles 32 Bit inputs and outputs and 		##
--## concatenates values into 128 bit values in order to compute the XTEA algorithm more 			##
--## efficiently.    																									##
--##                                                                                    			##
--## Dependencies: xtea_enc_dec.vhd, xtea_dec1_enc2.vhd, xtea_dec2_enc1.vhd    						##
--################################################################################################

-- Library declarations
LIBRARY IEEE;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

-- Entity definition
ENTITY xtea_top IS
PORT(
				
				clk            : IN  STD_LOGIC;
            reset_n        : IN  STD_LOGIC;
            encryption     : IN  STD_LOGIC; -- Flag to set decrpytion / encryption mode.
            key_data_valid : IN  STD_LOGIC; -- Signal to start data incoming
            data_word_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); -- Holds a single word of input data at a time
            key_word_in    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); -- Holds a single word of the key at a time
            data_word_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Holds a single word of output data at a time
            data_ready     : OUT STD_LOGIC -- Signal to start data outgoing
		);
END ENTITY xtea_top;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_top IS
	 
	 	 -- XTEA Decoding & Encoding Component
    COMPONENT xtea_enc_dec IS
        PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				start				: IN  STD_LOGIC;
				dec_enc_flag 	: IN  STD_LOGIC;

				key_in			: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_in   		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_out  		: OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
				data_ready 		: OUT STD_LOGIC
        );
    END COMPONENT xtea_enc_dec;
 
    -- Key/data input interface signals
	SIGNAL s_start       				: STD_LOGIC := '0';
	SIGNAL s_data_in         			: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');
	SIGNAL s_key_in          			: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');

	-- Data output interface signals
	SIGNAL s_data_out       			: STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');
	SIGNAL s_data_ready     			: STD_LOGIC := '0';
	
	-- State Signals
	-- Creates a type of signal known as t_state comprised of the states of the system.
	type t_state is (idle, keydatain1, keydatain2, keydatain3, encdec, output1, output2, output3, output4); 
	-- Create signals of type t_state to control the current and next state.
	signal State, NextState : t_state;
	
BEGIN
	
	-- Permanantly link signals to the output / input ports.
	data_ready <= s_data_ready;
	 
	-- Instanciate the encoding & Decoding component.
	enc_dec : xtea_enc_dec PORT MAP(
		clk            => clk,
		reset_n        => reset_n,
		start 			=> s_start,
		dec_enc_flag 	=> encryption,
		key_in    		=> s_key_in,
		data_in   		=> s_data_in,
		data_out  		=> s_data_out,
		data_ready 		=> s_data_ready
		);

-- Process block to decode the next state of the system
Next_State_Decode : process (clk, State,key_data_valid, s_data_ready) begin
 
		case (State) is
		
			when idle =>
			
            if key_data_valid = '1' then -- Wait until key_data_valid goes high, signaling data incoming to the FPGA.
					NextState <= keydatain1; -- Set the next state to the Key Data in Stage.
				else NextState <= idle;
				end if;

			-- Run through the input states.
			when keydatain1 => 
				 NextState <= keydatain2;
					 
			when keydatain2 => 
				 NextState <= keydatain3;
					 
			when keydatain3 => 
				 NextState <= encdec; -- Once all data has been collected move to the encoding / decoding stage.
			
			when encdec => 
			
				if s_data_ready = '1' then -- Wait until internal data ready signal goes high, signalling the end of decoding / encoding.
                NextState <= output1; -- Set the next state to the output states.
            else NextState <= encdec;  
            end if;
				
			-- Run through the output states.
			when output1 =>

				NextState <= output2;
				
			when output2 =>

				NextState <= output3;
				
			when output3 =>

				NextState <= output4;
				
			when output4 =>

				NextState <= idle; -- Once output is finished set the state back to idle.

		end case;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved.
Output_Decode : process (State, key_data_valid, key_word_in, data_word_in, s_data_out) begin
		case (State) is
		
			-- Idle / Reset State
			when idle =>

				s_start <= '0'; --Reset Start Variable
				data_word_out <= (others => '0'); -- Set 32 Bit Output to 0
				
				if key_data_valid = '1' then -- If data incoming from testbench
				
					-- Apply the first 32 bits in the reset state, this saves a clock cycle. First 32 bits must latch.
					s_key_in(31 DOWNTO 0) <= key_word_in;
					s_data_in(31 DOWNTO 0) <= data_word_in;
					
				end if;
				
			when keydatain1 => 
				
				s_start <= '0'; -- Explicitly latching s_start to 0 removes inferred latches.
				data_word_out <= (others => '0'); -- Explicit 0 latching for removing inferred latches.
				
				-- Insert the next word into the 2nd 32 bit range of the 128 bit input.
				s_key_in(63 DOWNTO 32) <= key_word_in; 
				s_data_in(63 DOWNTO 32) <= data_word_in;
				
			when keydatain2 => 
				
				s_start <= '0';
				data_word_out <= (others => '0');
				
				-- Insert the next word into the 3rd 32 bit range of the 128 bit input.
				s_key_in(95 DOWNTO 64) <= key_word_in;
				s_data_in(95 DOWNTO 64) <= data_word_in;
				
			when keydatain3 => 
				
				s_start <= '0';
				data_word_out <= (others => '0');
				
				-- Insert the next word into the 4th 32 bit range of the 128 bit input.
				s_key_in(127 DOWNTO 96) <= key_word_in;
				s_data_in(127 DOWNTO 96) <= data_word_in;
				
			when encdec => 
			
				s_start <= '1'; -- Trigger the encoding / decoding instanciated component.
				data_word_out <= (others => '0');
				
			when output1 =>
				
				s_start <= '0';
				--Set the first word out as the first 32 bits of the 128 data set.
				data_word_out <= s_data_out(31 DOWNTO 0);
				
			when output2 =>
				
				s_start <= '0';
				--Set the second word out as the second 32 bits of the 128 data set.
				data_word_out <= s_data_out(63 DOWNTO 32);
			
			when output3 =>
				
				s_start <= '0';
				--Set the third word out as the third 32 bits of the 128 data set.
				data_word_out <= s_data_out(95 DOWNTO 64);
				
			when output4 =>
				
				s_start <= '0';
				--Set the fourth word out as the last 32 bits of the 128 data set.
				data_word_out <= s_data_out(127 DOWNTO 96);
				
		end case;
end process;

-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (Clk, reset_n) begin  
	if reset_n = '0' then
		 state <= idle; -- Sets the default state of the system.
	elsif rising_edge(clk) then
		 State <= NextState;
	end if;
end process;
	 
end Behavioral;