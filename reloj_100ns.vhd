----------------------------------------------------------------------------------
-- CENTRO NACIONAL DE METROLOGÍA
-- Subdirección de Automatización Electrónica
--
-- Ing. José Carlos Guerrero Buenrostro
----------------------------------------------------------------------------------
-- Timer de 32 bit en Segundos y 32 bit en Fracciones de Segundo
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
----------------------------------------------------------------------------------
-- Declaracion de la entidad
----------------------------------------------------------------------------------
entity Timer_64bit is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  enable : in STD_LOGIC;
			  --lee_dato : in STD_LOGIC;
			  frac_seg : out STD_LOGIC_VECTOR (31 downto 0);
           seg : out  STD_LOGIC_VECTOR (31 downto 0));
end Timer_64bit;

----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
architecture Behavioral of Timer_64bit is

signal Counter : STD_LOGIC_VECTOR (31 downto 0):=(others => '0'); -- Inicio en 0
signal count :STD_LOGIC_VECTOR (26 downto 0):=(others => '0');-- integer :=0;
signal clk_1Hz : std_logic :='0';

----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
begin

frac_seg <= '0' & '0' & '0' & '0' & '0' & count;-- conv_std_logic_vector(count,32);
seg <= Counter;	

----------------------------------------------------------------------------------
-- Genera un reloj de 1Hz a partir de un reloj de 100 MHz.
---------------------------------------------------------------------------------- 
process(clk, Reset, Enable)
begin
	if reset = '1' then
		count <=(others => '0');--0;
		elsif rising_edge(clk) and enable = '1' then
			count <=count+1;
--			if(count = 49999999) then
--				clk_1Hz <= not clk_1Hz;
--			end if;
			if (count = 99999999) then
				clk_1Hz <='1';
				count <=(others => '0');--0;
				else
				clk_1Hz <='0';
			end if;
	end if;
end process;



process(clk_1Hz, Reset, Enable )
  begin
    if Reset='1' then
       Counter <= (others => '0');	-- Si reset esta en 1 la cuenta vuelve a 0
     elsif rising_edge(clk_1Hz) then	-- si hay flaco positivo del reloj
      if Enable='1' then				-- Si Enable esta en Bajo
			Counter <= Counter + 1;	
		else
         Counter <= Counter;
      end if;
    end if;
  end process; 
  
		




end Behavioral;

