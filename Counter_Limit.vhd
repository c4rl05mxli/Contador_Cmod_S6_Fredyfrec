----------------------------------------------------------------------------------
-- CENTRO NACIONAL DE METROLOGÍA
-- Subdirección de Automatización Electrónica
--
-- Ing. José Carlos Guerrero Buenrostro
----------------------------------------------------------------------------------
-- contador con limite de flanco y cuenta positiva, con limite de pulso y output
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Declaracion de la entidad
----------------------------------------------------------------------------------
entity Counter_Limit is
		Port ( 
				clk : in  STD_LOGIC;
				Pulse : in  STD_LOGIC;			
				Reset : in  STD_LOGIC;
				Enable : in STD_LOGIC;
				Signal_Control : out STD_LOGIC;
				Pulse_Limit : in STD_LOGIC_VECTOR (31 downto 0);
				Timer_Limit : in STD_LOGIC_VECTOR (15 downto 0)
				);
end Counter_Limit;
		 
		 
architecture Behavioral of Counter_Limit is
----------------------------------------------------------------------------------
-- Declaracion de Señales y Arquitectura
----------------------------------------------------------------------------------

signal Pulse_Counter : STD_LOGIC_VECTOR (31 downto 0):=(others => '0'); -- Inicio en 0
signal Timer_Counter : STD_LOGIC_VECTOR (15 downto 0):=(others => '0'); -- Inicio en 0
signal count : STD_LOGIC_VECTOR (26 downto 0):=(others => '0');--integer :=0;
signal clk_1Hz : std_logic :='0';
signal control : std_logic :='0';

begin
----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
Signal_Control <= control;

process(Pulse_Counter, Pulse_Limit, Timer_Counter, Timer_Limit)			--Este fragmento de codigo emula un latch con SET, RESET
	begin
	IF (Pulse_Counter > Pulse_Limit or Timer_Counter >= Timer_Limit) then--or Enable='0' THEN		-- Cuando el numero es mayor al limite se va a reset
		control <='0';
	ELSIF (Pulse_Counter > 0) THEN		-- Cuando el numero es mayor que cero activa el set
		control <='1';
	ELSE
		control<='0';	-- El latch, tiene prioridad en el reset
	END IF;	
end process;



process(Pulse, Reset, Enable )
  begin
    if Reset='1' then
       Pulse_Counter <= (others => '0');	-- Si reset esta en 1 la cuenta vuelve a 0
		 --Signal_Control<='0';
     elsif rising_edge(Pulse) then	-- si hay flaco positivo del reloj
      if Enable='1' then		
			Pulse_Counter <= Pulse_Counter + 1;			
		else
         Pulse_Counter<= Pulse_Counter;
     end if;
    end if;
  end process; 
  
----------------------------------------------------------------------------------
-- Genera un reloj de 1Hz a partir de un reloj de 100 MHz.
---------------------------------------------------------------------------------- 
process(clk, Reset)--, control)
begin
	if reset = '1' then
		count <= (others => '0'); --0;
		elsif rising_edge(clk) then --and control= '1' then
			count <=count+1;
			if (count = 99999999) then
				clk_1Hz <='1';
				count <= (others => '0');--0;
				else
				clk_1Hz <='0';
			end if;
	end if;
end process;
  


process(clk_1Hz, Reset, control )
  begin
    if Reset='1' then
       Timer_Counter <= (others => '0');	-- Si reset esta en 1 la cuenta vuelve a 0
     elsif rising_edge(clk_1Hz) then	-- si hay flaco positivo del reloj
      if control='1' then				-- Si Enable esta en Bajo
			Timer_Counter <= Timer_Counter + 1;	
		else
         Timer_Counter <= Timer_Counter;
      end if;
    end if;
 end process; 
  
  
  
  
  
end Behavioral;