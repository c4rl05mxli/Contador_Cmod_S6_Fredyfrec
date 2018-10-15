----------------------------------------------------------------------------------
-- CENTRO NACIONAL DE METROLOGÍA
-- Subdirección de Automatización Electrónica
--
-- Ing. José Carlos Guerrero Buenrostro
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Declaracion de la entidad
----------------------------------------------------------------------------------
entity Master_Control is
		Port ( 
				clk: in  STD_LOGIC;
				Pulse_A : in  STD_LOGIC;
				Pulse_B : in  STD_LOGIC;				
				Reset : in  STD_LOGIC;
				Enable : in STD_LOGIC;
				Pulse_Max : in STD_LOGIC_VECTOR (31 downto 0);		-- Limite de cuenta en pulsos
				Timer_Max : in STD_LOGIC_VECTOR (15 downto 0);		-- Limite de cuenta en Tiempo
				--- SALIDAS DEL SISTEMA ---
				Cnt_A_Enable : out STD_LOGIC;	
				Cnt_B_Enable : out STD_LOGIC;
				T1_Enable :	out STD_LOGIC;
				T2_Enable :	out STD_LOGIC	
				);
end Master_Control;




architecture Behavioral of Master_Control is

signal Detector_Signal : STD_LOGIC;
signal control_1 :std_logic;
signal control_2 :std_logic;

---	Señales del Control Logico	---
signal D1,D2 : std_logic;
signal T1,T2 : std_logic;
signal Detector : std_logic;
signal Pulses : std_logic;

signal Pulse: std_logic;

signal control: std_logic;
signal Pulse_Counter : STD_LOGIC_VECTOR (31 downto 0):=(others => '0'); -- Inicio en 0
signal Pulse_Limit:STD_LOGIC_VECTOR (31 downto 0):=(others => '0'); -- Inicio en 0

---- señales para el control del tiempo	---
signal count : STD_LOGIC_VECTOR (26 downto 0):=(others => '0');--integer :=0;
--signal clk_1Hz : std_logic :='0';
signal Timer_Counter : STD_LOGIC_VECTOR (15 downto 0):=(others => '0'); -- Inicio en 0
signal Timer_Limit : STD_LOGIC_VECTOR (15 downto 0):=(others => '0'); -- Inicio en 0

signal Time_control : std_logic:='1';


begin

Pulse <= Pulse_A;  	-- Pulsos filtrados del Patron
Pulses <= Pulse_B;	-- Pulsos filtrados del IBC
Pulse_Limit <= Pulse_Max;	-- Limite del pulsos
--
Timer_Limit <=Timer_Max;	-- Limite de Tiempo


--Proceso del patron
process(Pulse, Reset)
  begin
    if Reset='1' then
       Pulse_Counter <= (others => '0');	-- Si reset esta en 1 la cuenta vuelve a 0
     elsif Pulse'event and Pulse='1' then			-- si hay flaco positivo del patron
      if Enable='1' then		
			Pulse_Counter <= Pulse_Counter + 1;				
		else
         Pulse_Counter <= Pulse_Counter;
     end if;  
    end if;
end process; 



-- Limite de pulsos del patron
--- Este flip flip sirve para hacer sincrona la señal del Detector.
process (clk)
begin
   if clk'event and clk='1' then  
      if Reset='1' then   
         Detector <='0';
      elsif (Pulse_Counter > 0 and Pulse_Counter <= Pulse_Limit ) then
			Detector <='1';	-- inicio la maquina de estado del doble cronometria
		else
			Detector <='0';
      end if;
   end if;
end process;


------- seccion de control por tiempo -------------------

----------------------------------------------------------------------------------
-- Genera un reloj de 1Hz a partir de un reloj de 100 MHz.
---------------------------------------------------------------------------------- 
process(clk, Reset)
begin
	if Reset = '1' then							-- Si reset esta en 1 las cuentas vuelven a 0
		count <= (others => '0');				-- Contador de Decimas de nanosegundo
		Timer_Counter <= (others => '0');	-- Contador de Segundos
		Time_control <='1';
		elsif clk'event and clk='1' then 	-- en el ciclo flanco positivo del reloj
			if Detector ='1' then
				if Timer_Counter >= Timer_Limit then
							Time_control <= '0';
				else
				count <= count+1;					-- incremento 10 ns
					if (count = 99999999) then		-- si ya paso un segundo
						Timer_Counter <= Timer_Counter + 1;	
						count <= (others => '0');	--	Regreso el contador de nanodecimas a 0
					else
						Timer_Counter <= Timer_Counter;
					end if;
				end if;
			end if;
	end if;
end process;


--- Aqui hay ff con reset asincrono que causan problemas de propagacion y tiempo es necesario quitarlos ----
---	Seccion de Codigo del Control Logico	---
process (Detector, Reset)
begin
   if Reset='1' then   
      D1 <= '0';
   elsif (Detector'event and Detector='1') then 
      D1 <= '1';
   end if;
end process;

-- proceso referenciado al patron
process (Detector, Reset)
begin
   if Reset='1' then   
      D2	<= '0';
   elsif (Detector'event and Detector='0') then 
		D2	<= '1';
   end if;
end process;

-- Referenciado a Pulses, que es señal filtrada B y es el IBC
process (Pulses, Reset)
begin
   if Reset='1' then   
      T2 <= '0';
   elsif (Pulses'event and Pulses='1') then 
      T2 <= T1;
   end if;
end process;

T1 <= (D1 xor D2) and Enable and Time_control;
------------------------------------------------

--- Salidas del Sistema de Control	---
Cnt_A_Enable <= T1;  -- Flag que habilita contador A, patron
Cnt_B_Enable <= T2;  -- Flag que habilita contador B, IBC
T1_Enable 	<= T1;	-- Flag que habilita temporizador A, patron
T2_Enable 	<= T2;	-- Flag que habilita temporizador B, IBC
------------------------------------------------


end Behavioral;

