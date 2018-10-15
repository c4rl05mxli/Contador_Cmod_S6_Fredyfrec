----------------------------------------------------------------------------------
-- CENTRO NACIONAL DE METROLOGÍA
-- Subdirección de Automatización Electrónica
--
-- Ing. José Carlos Guerrero Buenrostro
----------------------------------------------------------------------------------
-- Circuito Eliminador de rebotes
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
----------------------------------------------------------------------------------
-- Declaracion de la entidad
--https://eewiki.net/pages/viewpage.action?pageId=4980758
----------------------------------------------------------------------------------
ENTITY debounce IS
  GENERIC(
			N  :  INTEGER := 8 --19  -- Tiempo de rebotes = (2^N+2)/(clk)= (2^19+2)/(100MHz)= 
			);
  PORT(
		clk     : IN  STD_LOGIC;  --señal de reloj CLK
		button  : IN  STD_LOGIC;  --input
		result  : OUT STD_LOGIC
		); --output
END debounce;
----------------------------------------------------------------------------------
-- Declaracion de la arquitectura
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF debounce IS
  SIGNAL flipflops   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops
  SIGNAL counter_set : STD_LOGIC;                    --sync reset to zero
  SIGNAL counter_out : STD_LOGIC_VECTOR(N DOWNTO 0) := (OTHERS => '0'); --counter output
----------------------------------------------------------------------------------
-- Inicio del Codigo
----------------------------------------------------------------------------------
BEGIN

  counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter
  
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT and clk = '1') THEN
      flipflops(0) <= button;
      flipflops(1) <= flipflops(0);
      If(counter_set = '1') THEN                  --reset counter because input is changing
        counter_out <= (OTHERS => '0');
      ELSIF(counter_out(N) = '0') THEN 				--stable input time is not yet met
        counter_out <= counter_out + 1;
      ELSE                                        --stable input time is met
        result <= flipflops(1);
      END IF;    
    END IF;
  END PROCESS;
END Behavioral;
