----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2019 02:07:56 PM
-- Design Name: 
-- Module Name: principal - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.STD_LOGIC_1164.ALL;

entity principal is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ena : in STD_LOGIC;
           scl : inout STD_LOGIC;
           sda : inout STD_LOGIC;
            an   : out STD_LOGIC_VECTOR (3 downto 0);   
           seg  : out STD_LOGIC_VECTOR (6 downto 0);
           LED:out STD_LOGIC_VECTOR(8 downto 0);
           ack:OUT STD_LOGIC);   
end principal;

architecture Behavioral of principal is
component SSD is
    Port ( Digit0 : in STD_LOGIC_VECTOR (3 downto 0);
           Digit1 : in STD_LOGIC_VECTOR (3 downto 0);
           Digit2 : in STD_LOGIC_VECTOR (3 downto 0);
           Digit3 : in STD_LOGIC_VECTOR (3 downto 0);
           CLK : in STD_LOGIC;
           CAT : out STD_LOGIC_VECTOR (6 downto 0);
           AN : out STD_LOGIC_VECTOR (3 downto 0));
end component SSD;


component controller_i2c IS
  GENERIC(
    frecventa_in : INTEGER := 100_000_000; 
    frecventa_out   : INTEGER := 400_000);
  PORT(
    clk:in STD_LOGIC;                   
    rst:in STD_LOGIC;                   
    ena:in STD_LOGIC;                    
    data_rd:out STD_LOGIC_VECTOR(7 DOWNTO 0); 
    sda:inout  STD_LOGIC;                    
    scl:inout  STD_LOGIC;                 
    led:out std_logic_vector(8 downto 0);
    ack:out STD_LOGIC);
END component controller_i2c;

component debounce is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           d_in : in STD_LOGIC;
           q_out : out STD_LOGIC);
end component debounce;
signal data:  STD_LOGIC_VECTOR(7 downto 0):=(others=>'0');
signal rst_debounced:STD_LOGIC;
begin
debounce_buton_reset:debounce port map(
    clk=>clk,
    rst=>'0',
    d_in=>rst,
    q_out=>rst_debounced);
automat: controller_i2c port map(
           clk => clk,
           rst=> rst_debounced, 
           ena => ena,
           data_rd=>data,
           sda => sda,
           scl=>scl,
           led=>led,
           ack =>ack);
afisor:SSD port map(data(7 downto 4),data(3 downto 0),"UUUU","1100",clk,seg,an);
end Behavioral;
