----------------------------------------------------------------------------------
-- Company: Covnetics Limited (at the time of development)
-- Engineer: ED72
-- 
-- Create Date:    09:33:24 18/10/2022 
-- Design Name: 
-- Module Name:    RISC_V_Core - Behavioral 
-- Project Name:   RISC_V
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package AXI_pkg is
-- Definitions
    type e_state is (IDLE, WRITE_ADDRESS, WRITE_DATA, WRITE_RESPONSE, READ_ADDRESS, READ_DATA);  -- enumerated states
	type wa_state is (WA_IDLE, WA_DETECTED, WA_ACKNOWLEDGED);  -- enumerated states
	type ra_state is (RA_IDLE, RA_DETECTED, RA_ACKNOWLEDGED);  -- enumerated states
	type wr_state is (WR_IDLE, WR_SAMPLED, WR_DELAYED, WR_LAST, WR_CONFIRM);  -- enumerated states
	type rd_state is (RD_IDLE, RD_UPDATE, RD_LAST);  -- enumerated states
    type response is (OKAY, EXOKAY, SLVERR, DECERR);
    type burst is (FIXED, INCR, WRAP, RESERVED);
    attribute enum_encoding             : string;
    attribute enum_encoding of e_state  : type is "000000001 000000010 000000100 000001000 000010000 000100000 001000000 010000000 100000000"; -- One-Hot encoding
    attribute enum_encoding of response : type is "00 01 10 11"; -- Binary encoding
    attribute enum_encoding of burst    : type is "00 01 10 11"; -- Binary signal

-- Constant Declaration
-- Test file - To be modified by TCL command for different test scenarios
    constant TestFile                  : string := "C:\Users\donkove\Documents\QSIM\AXI\Source/AXI_Test_1_V1_3.txt";
-- Defaults
    constant Burst_Length              : positive := 8;
    constant Burst_Size                : positive := 3;
    constant Write_Data_Bus            : positive := 64;
    constant Read_Data_Bus             : positive := 64;
    constant Write_Address_Bus         : positive := 32;
    constant Read_Address_Bus          : positive := 32;
    constant Slave_Memory_Size         : positive := 1024;
    constant Burst_Max_Size            : positive := 128;  -- bytes per transaction, depends on data bus
    constant Burst_Max_Lenth           : positive := 1024;
	constant AWID_Bus                  : positive := 8;
	constant ARID_Bus                  : positive := 8;
	constant WID_Bus                   : positive := 8;
	constant RID_Bus                   : positive := 8;
	constant BID_Bus                   : positive := 8;
-- Reset Defaults
    constant AXI_DEF_RDBUS             : std_logic_vector ((Read_Data_Bus-1) downto 0) := (others =>'0');
	constant AXI_DEF_WDBUS             : std_logic_vector ((Write_Data_Bus-1) downto 0) := (others =>'0');
	constant AXI_DEF_ARBUS             : std_logic_vector ((Read_Address_Bus-1) downto 0) := (others =>'0');
	constant AXI_DEF_AWBUS             : std_logic_vector ((Write_Address_Bus-1) downto 0) := (others =>'0');
--	constant AXI_DEF_RDBUS             : std_logic := '0';
-- Master
    constant Master_Write_Data_Bus     : positive := 64;
    constant Master_Read_Data_Bus      : positive := 64;
    constant Master_Write_Address_Bus  : positive := 32;
    constant Master_Read_Address_Bus   : positive := 32;
-- Slave 1
    constant Slave_1_Write_Data_Bus    : positive := 64;
    constant Slave_1_Read_Data_Bus     : positive := 64;
    constant Slave_1_Write_Address_Bus : positive := 32;
    constant Slave_1_Read_Address_Bus  : positive := 32;
-- Slave 2
    constant Slave_2_Write_Data_Bus    : positive := 64;
    constant Slave_2_Read_Data_Bus     : positive := 64;
    constant Slave_2_Write_Address_Bus : positive := 32;
    constant Slave_2_Read_Address_Bus  : positive := 32;
-- Slave 3
    constant Slave_3_Write_Data_Bus    : positive := 64;
    constant Slave_3_Read_Data_Bus     : positive := 64;
    constant Slave_3_Write_Address_Bus : positive := 32;
    constant Slave_3_Read_Address_Bus  : positive := 32;
-- Functions Declaration
    function verify(a,b : in STD_LOGIC_VECTOR (7 downto 0)) return boolean;  -- tests if passed character is a valid (case insensitive) hexadecimal character
	function convert_burst_type(a: in integer range 0 to 7) return burst; 
	function std_burst_type(a: in integer range 0 to 7) return STD_LOGIC_VECTOR; 
    function get_burst_type(a: in STD_LOGIC_VECTOR (1 downto 0)) return burst; 
    function get_response_type(a: in STD_LOGIC_VECTOR (1 downto 0)) return response;
    function get_burst_size(a: in STD_LOGIC_VECTOR (2 downto 0)) return positive;
	
end AXI_pkg;

package body AXI_pkg is
 
    function verify(a,b : in STD_LOGIC_VECTOR (7 downto 0)) return boolean is
       begin
	      if (a=b) then  return(true);
		  end if;
       end function verify;
	      
    function get_burst_type(a: in STD_LOGIC_VECTOR (1 downto 0)) return burst is
       begin
	      case a is
            when "00" => return (FIXED);
            when "01" => return (INCR);
            when "10" => return (WRAP);
            when "11" => return (RESERVED);
            when others => return (RESERVED);
          end case;
       end function get_burst_type;
	   
	function convert_burst_type(a: in integer range 0 to 7) return burst is
       begin
	      case a is
            when 0 => return (FIXED);
            when 1 => return (INCR);
            when 2 => return (WRAP);
            when 3 => return (RESERVED);
            when others => return (RESERVED);
          end case;
       end function convert_burst_type;
	   
	function std_burst_type(a: in integer range 0 to 7) return STD_LOGIC_VECTOR is
       begin
	      case a is
            when 0 => return ("00");
            when 1 => return ("01");
            when 2 => return ("10");
            when 3 => return ("11");
            when others => return ("01");
          end case;
       end function std_burst_type;
	        
    function get_response_type(a: in STD_LOGIC_VECTOR (1 downto 0)) return response is
       begin
	      case a is
            when "00" => return (OKAY);
            when "01" => return (EXOKAY);
            when "10" => return (SLVERR);
            when "11" => return (DECERR);
            when others => return (DECERR);
          end case;
       end function get_response_type;
       
    function get_burst_size(a: in STD_LOGIC_VECTOR (2 downto 0)) return positive is
       begin
	      case a is
            when "000" => return (1);
            when "001" => return (2);
            when "010" => return (4);
            when "011" => return (8);
            when "100" => return (16);
            when "101" => return (32);
            when "110" => return (64);
            when "111" => return (128);
            when others => return (1);
          end case;
       end function get_burst_size;

end AXI_pkg;