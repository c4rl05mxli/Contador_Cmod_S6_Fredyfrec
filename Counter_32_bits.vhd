----------------------------------------------------------------------------------
-- CENTRO NACIONAL DE METROLOGÍA
-- Subdirección de Automatización Electrónica
--
-- Ing. José Carlos Guerrero Buenrostro
----------------------------------------------------------------------------------
-- contador de 32 bits de flanco y cuenta positiva
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Declaracion de la entidad
----------------------------------------------------------------------------------
entity Counter_32_bits is
		Port ( 
				Pulse : in  STD_LOGIC;			
				Reset : in  STD_LOGIC;
				Enable : in STD_LOGIC;
				Count : out STD_LOGIC_VECTOR (31 downto 0)
				);
end Counter_32_bits;
		 
		 
architecture Behavioral of Counter_32_bits is
----------------------------------------------------------------------------------
-- Declaracion de Señales y Arquitectura
----------------------------------------------------------------------------------

signal Counter : STD_LOGIC_VECTOR (31 downto 0):=(others => '0'); -- Inicio en 0

begin
----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------

process(Pulse, Reset, Enable )
  begin
    if Reset='1' then
       Counter <= (others => '0');	-- Si reset esta en 1 la cuenta vuelve a 0
     elsif rising_edge(Pulse) then	-- si hay flaco positivo del reloj
      if Enable='1' then		
			-- Si Enable esta en Alto
				Counter <= Counter + 1;	
		else
         Counter <= Counter;
      end if;
    end if;
  end process; 
  
Count <= Counter;							-- Saco el Valor del Counter por el LATCH Count
end Behavioral;

