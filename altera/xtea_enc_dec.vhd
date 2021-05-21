--################################################################################################
--## Developer: Chris Holland (B726822)                                                  			##
--##                                                                                    			##
--## Design name: xtea                                                                  			##
--## Module name: xtea_enc_dec - Encoding and Decoding Container                            		##
--## Target devices: Altera DE1-SOC Prototyping Board                                   			##
--## Tool versions: Quartus Prime Lite Edition 19.1, ModelSim Intel FPGA Starter Edition 10.5b  ##
--##                                                                                    			##
--## Description: Utilising the 128 bit inputs from xtea_top, this module performs both xtea		##
--## 					decrpytion and encrpytion utilising 2 instanciated components, each				##
--## 					pertaining to a step of the xtea algorithm. This result is then passed back	##
--## 					the xtea top for final stage output processing.											##
--##                                                                                    			##
--## Dependencies: xtea_top.vhd                                                        			##
--################################################################################################

-- Library declarations
LIBRARY IEEE;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

-- Entity definition
ENTITY xtea_enc_dec IS
PORT(
            clk            : IN  STD_LOGIC;
				reset_n			: IN  STD_LOGIC;
				start				: IN  STD_LOGIC;	
				dec_enc_flag 	: IN  STD_LOGIC;

				key_in		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            data_in   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
				
            data_out  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
				data_ready		: OUT STD_LOGIC
);
END ENTITY xtea_enc_dec;

-- Arcvhitecture definition
ARCHITECTURE Behavioral OF xtea_enc_dec IS
	
	-- XTEA Part 1 Decoding / Part 2 Encoding Component
	COMPONENT xtea_dec1_enc2 IS
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
			z0_new 				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec1_enc2;
 
	-- XTEA Part 2 Decoding / Part 1 Encoding Component
	COMPONENT xtea_dec2_enc1 IS
	  PORT(
			reset_n			: IN  STD_LOGIC;
			dec_enc_flag 	: IN  STD_LOGIC;
			sum				: IN  unsigned(31 DOWNTO 0);
			key				: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			z1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			z0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y1    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0    			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			y1_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			y0_new  				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT xtea_dec2_enc1;
	
	--Processing Signals
	SIGNAL s_y0, s_y1, s_z0, s_z1 						: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
	SIGNAL s_y0_new, s_y1_new, s_z0_new, s_z1_new 	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); 
	SIGNAL s_data_ready 	: STD_LOGIC := '0';
	SIGNAL s_sum 			: unsigned(31 DOWNTO 0):= (others => '0');
	
	-- Constant Declaration
	constant total_cycles: unsigned(7 downto 0) := to_unsigned(32, 8);
	constant delta 			: unsigned (31 downto 0) := x"9E3779B9";
	constant sum_dec_init 	: unsigned (31 downto 0) := x"C6EF3720";
	constant sum_enc_init	: unsigned (31 downto 0) := (others => '0');
	
	--State Signals
	type t_state is (StartState, ProcessStateD1E2, ProcessStateD2E1, OutputState); -- Creates a type of signal known as t_state comprised of the states of the system.
	signal State, NextState : t_state; -- Create signals of type t_state to control the current and next state.

BEGIN
	
	-- Instanciate an encoding and decoding component, handles the first decoding step, and second encoding step.
	encdec1 : xtea_dec1_enc2
	PORT MAP(
		reset_n     	=> reset_n,
		dec_enc_flag 	=> dec_enc_flag,
		sum 				=> s_sum,
		key 				=> key_in,
		y1     			=> s_y1,
		y0    			=> s_y0,
		z1     			=> s_z1,
		z0    			=> s_z0,
		z1_new     		=> s_z1_new,
		z0_new  			=> s_z0_new
	);
	 
	-- Instanciate an encoding and decoding component, handles the second decoding step, and first encoding step.
	encdec2 : xtea_dec2_enc1
	PORT MAP(
		reset_n     	=> reset_n,
		dec_enc_flag 	=> dec_enc_flag,
		sum 				=> s_sum,
		key 				=> key_in,
		z1     			=> s_z1,
		z0    			=> s_z0,
		y1     			=> s_y1,
		y0    			=> s_y0,
		y1_new     		=> s_y1_new,
		y0_new  			=> s_y0_new
	);

-- Process block to decode the next state of the system
Next_State_Decode : process (clk)
variable ns_iterator : unsigned(7 downto 0); -- Set a variable to increment over the process of the encrpytion/decryption.
															-- This variable will control state transitions throughout.
begin 
	-- Depending on the State
	case (State) is
		when StartState =>
			-- When in the Reset/Idle state, reset the next state iterator to 0.
			ns_iterator := to_unsigned(0, 8);
			-- If the internal start signal from the top level has gone high, start the process.
			if start = '1' then
				-- If in decoding mode then set the next state to decode step 1 / encode step 2.
				if dec_enc_flag = '0' then
					NextState <= ProcessStateD1E2;
				-- If not in decoding mode (encoding mode) then set the next state to decode step 2 / encode step 1.
				else NextState <= ProcessStateD2E1;
				end if;
			-- If the start signal is not high, then remain in the idle StartState.
			else Nextstate <= StartState;
			end if;
			
		when ProcessStateD1E2 => 
			-- When in the decoding 1st step / Encoding 2nd step increment the iterator
			ns_iterator := ns_iterator + 1;
			
			-- With 32 cycles, incrementing the iterator on both the falling edge and rising edge of the clock,
			--	in addition to requiring 2 states to complete a full cycle of the XTEA algoirthm, only when the iterator
			-- is greaterthan or equal to the total cycles constant (32) * 4, then an additional 1 to deal with the decode process
			--	happening on the falling edge instead of the rising edge.
			if ns_iterator >= (total_cycles*4)-1 then 
				-- If this condition is true, the XTEA algorithm is complete and the output state should be selected.
				NextState <= OutputState;
			-- Otherwise set the next state to the 2nd setp decoding / Encoding 1st step.
			else NextState <= ProcessStateD2E1;
			end if;
		
		when ProcessStateD2E1 =>
		-- This logic is duplicated from the earlier state, however it is reversed, sending the next state back to the previous state.
			ns_iterator := ns_iterator + 1;
			if ns_iterator >= (total_cycles*4)-1 then
				 NextState <= OutputState;
			else NextState <= ProcessStateD1E2;
			end if;
			
		when OutputState =>
		-- When in the output state reamin incrementing the iterator as this can be used to check the amount of clock cycles has passed since this state began.
			ns_iterator := ns_iterator + 1;
			-- Hold the state in output state for long enough in order for the XTEA_top to break down the output and output it to the testbench / A9.
			-- 8 Clock cylces (9 Greater than the previous logic) allows the system enough time, as it takes 4 clock cycles to fully output the data.
			-- Making this number exactly correct has no impact, as the system is bottlenecked by the top level, meaning no efficiency gained by changing 8 to 7
			-- would make any differnence to the output of the system overall.
			if ns_iterator >= (total_cycles*4)+8 then
				 NextState <= StartState;
			else NextState <= OutputState;
			end if;
			
		when others =>
	end case;
end process;

-- Sum Process to handle the Sum calculation based on the state of the system, happens on the rising edge of the clock.
Sum_Process : process (dec_enc_flag, clk) begin
	-- Only if on the rising edge of the clock
	if rising_edge(clk) then
		-- Depending on the state
		case (State) is
			when StartState =>
				-- If the system is in encoding or decoding mode, set the initial value equal to the constant declared earlier.
				if dec_enc_flag = '1' then
					s_sum <= sum_enc_init;
				else s_sum <= sum_dec_init;
				end if;
				
			when ProcessStateD1E2 => 
				-- If the system is in decoding mode, decrement the sum value by the delta constant predefined.
				if dec_enc_flag = '0' then
					s_sum <= s_sum - delta;
				end if;
			
			when ProcessStateD2E1 => 
				-- If the system is in encoding mode, increment the sum value by the delta constant predefined.
				if dec_enc_flag = '1' then
					s_sum <= s_sum + delta;
				end if;
				
			-- If in any other state do nothing.
			when others =>
		end case;
	end if;
end process;

-- This process block controls the output of the system in each state based on the inputs and signal values involved, happens on the falling edge of the clock
-- Sum process needs to happen before this logic, hence the falling edge.
Output_Decode : process (clk) 
begin
	-- Only if on the falling edge of the clock
	if falling_edge(clk) then
		-- Depending on the state
		case (State) is
			when StartState =>
			
				-- When in idle, reset the data ready and the data output to 0.
				data_ready <= '0';
				data_out <= (others => '0');
				-- When in idle, set the processing signals to the data input port of the encoding/decoding component.
				s_y0 <= data_in(127 DOWNTO 96);
				s_z0 <= data_in(95 DOWNTO 64);
				s_y1 <= data_in(63 DOWNTO 32);
				s_z1 <= data_in(31 DOWNTO 0);
				
			when ProcessStateD1E2 => 
			
				data_ready <= '0';
				data_out <= (others => '0');
				-- When in the Decode 1st Step, Encoding 2nd step apply the new z0 and z1 values, overwriting the current values.
				s_z0 <= s_z0_new;
				s_z1 <= s_z1_new;

			when ProcessStateD2E1 => 
			
				data_ready <= '0';
				data_out <= (others => '0');
				-- When in the Decode 2nd Step, Encoding 1st step apply the new s0 and s1 values, overwriting the current values.
				s_y1 <= s_y1_new;
				s_y0 <= s_y0_new;
				
			when OutputState =>
			
				-- Set the internal data ready signal to high, this will set the testbench to read the data output in addition to moving the
				-- state machine on the higher level to output mode.
				data_ready <= '1';
				
				-- When in the output step, set the 128 bit data output port to the concatenation of all the system variables. 
				data_out <= STD_LOGIC_VECTOR(s_y0) & STD_LOGIC_VECTOR(s_z0) & STD_LOGIC_VECTOR(s_y1) & STD_LOGIC_VECTOR(s_z1);
			
			when others =>
		end case;
	end if;
end process;

-- This process allows the system to move between states and also sets the default state through the reset button.
Clock_Process : process (Clk, reset_n) begin  
	if reset_n = '0' then
		 state <= StartState; -- Sets the default state of the system.
	elsif rising_edge(clk) then
		 State <= NextState;
	end if;
end process;
	 
end Behavioral;