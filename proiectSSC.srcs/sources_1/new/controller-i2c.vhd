----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/08/2019 02:41:31 PM
-- Design Name: 
-- Module Name: controller-i2c - Behavioral
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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY controller_i2c IS
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
END controller_i2c;

ARCHITECTURE Behavioral OF controller_i2c IS
  CONSTANT perioada:INTEGER:=(frecventa_in/frecventa_out)/2;
  CONSTANT adresaSlave:STD_LOGIC_VECTOR(6 downto 0):="1001000";
  CONSTANT rw:STD_LOGIC:='1';
  TYPE tip IS(ready, start, command, slv_ack1, rd, mstr_ack, stop); 
  SIGNAL stare:tip;                       
  SIGNAL data_clk ,data_clk_prev,scl_clk,sda_aux,CE_f,CE_r: STD_LOGIC;                                         
              
  SIGNAL sda_int: STD_LOGIC := '1';         
  SIGNAL bit_cnt: INTEGER := 7;    
  SIGNAL tragescl:STD_LOGIC := '0';              
  signal data_rd_aux,data_aux :STD_LOGIC_VECTOR(7 downto 0):="00000000";
  signal count:INTEGER:=0;
BEGIN

gen_sclk:process(clk)
begin
IF(rst = '1') THEN                
      tragescl <= '0';
      count <= 0;
elsif (rising_edge(clk)) then
    data_clk_prev <= data_clk;
    if (count < perioada/2) then
        data_clk<='0';
        scl_clk<='0';
    elsif (count <perioada) then
        data_clk<='1';
        scl_clk<='0';
    elsif (count < perioada*3/2) then
        IF(scl = '0') THEN              
            tragescl <= '1';     --slave trage scl spre zero
          ELSE
            tragescl <= '0';     --slave nu modifica scl
          END IF;
        data_clk<='1';
        scl_clk<='1';
    elsif (count < perioada*2) then
        scl_clk<='1';
        data_clk<='0';
        if (count = perioada*2-1) then 
            count<=0;
        end if;
    end if;
if (tragescl = '0' and count/=perioada*2-1 ) then 
            count<=count +1;
        end if;
end if;
end process;
CE_r<=(data_clk) and NOT (data_clk_prev);   --CE pentru rising edge
CE_f<=NOT (data_clk) and (data_clk_prev);   --CE pentru falling edge
  PROCESS(clk, rst)
  BEGIN
    IF(rst = '1') THEN                
      stare <= ready;                 
      sda_int <= '1';
      bit_cnt <= 7;                        
      data_rd_aux <= "00000000";               
      led<="000000000";
      ack<='0';
    ELSIF(rising_edge(clk)) THEN
        CASE stare IS
          WHEN ready =>    
              IF(CE_r='1') THEN
                led(0)<='1';                 
                IF(ena = '1') THEN
                  stare <= start;               
                ELSE                        
                  stare <= ready;              
                END IF;
              end if;
          WHEN start =>  
             IF(CE_r='1') THEN
                led(1)<='1';  
                bit_cnt<=7;                   
                sda_int <= adresaSlave(bit_cnt-1);     
                stare <= command;      
             end if;
          WHEN command => 
             IF(CE_r='1') THEN
                led(2)<='1'; 
                IF(bit_cnt = 0) THEN            
                  sda_int <= '1';                
                  bit_cnt <= 7;                
                  stare <= slv_ack1;           
                ELSE                          
                  if (bit_cnt >=2) then
                    sda_int <= adresaSlave(bit_cnt-2);
                  else sda_int<=rw;
                  end if;
                  bit_cnt <= bit_cnt - 1;
                  stare <= command;            
                END IF;
              end if;
          WHEN slv_ack1 =>     
             IF(CE_r='1') THEN
                led(3)<='1';               
                IF(rw = '0') THEN       
                stare <= stop;                   
                ELSE                           
                  sda_int <= '1';           --release sda pt a accepta date    
                  stare <= rd;                   
                END IF;
             elsif (CE_f='1') then
                if (sda/='0') then ack<='1';
                end if;
             end if;  
          WHEN rd =>           
             IF(CE_r='1') THEN
                  led(4)<='1';            
                  IF(bit_cnt = 0) THEN             
                      bit_cnt <= 7;                  
                      data_rd_aux <= data_aux;  
                      stare <= mstr_ack;             
                   ELSE                             
                      bit_cnt <= bit_cnt - 1;        
                      stare <= rd;                   
                    END IF;
              elsif (CE_f='1') then
                 data_aux(bit_cnt) <= sda; 
              end if;
          WHEN mstr_ack =>  
             IF(CE_r='1') THEN        
                  led(5)<='1'; 
                  IF(ena = '1' ) THEN  
                        sda_int <= '0';          --ack   
                  ELSE                          
                        sda_int <= '1';          --not ack
                  END IF;     
                  stare <= stop;   
             end if;             
          WHEN stop => 
          IF(CE_r='1') THEN             
             led(6)<='1';      
          end if;  
        END CASE;
    END IF;
  END PROCESS;  


process(stare)
begin
 case stare is
    when start=> sda_aux<=data_clk_prev;  --cond start
    when stop => sda_aux <= NOT data_clk_prev;   --cond stop
    when others => sda_aux <= sda_int;
 end case;
 if (scl_clk = '0') then scl<='0';
 else scl<='Z';
 end if;
 if (sda_aux='0') then sda<='0';
 else sda<='Z';
 end if;
end process;

data_rd<=data_rd_aux;
END Behavioral;

