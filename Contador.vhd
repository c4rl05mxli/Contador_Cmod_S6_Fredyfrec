----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;
--
entity Contador is    
Port ( 				  led : out std_logic_vector(3 downto 0);
							TG : out std_logic_vector(5 downto 0);
                   -- switch : in std_logic_vector(3 downto 0);
						Pulsos_A : in std_logic;
						Pulsos_B : in std_logic;
						Enable_1 : out std_logic;
						Enable_2 : out std_logic;
						------------------------------
						--Led_aviso : out std_logic;
						
						Pin1: out std_logic;
						Pin2: out std_logic;
						
					--	Start     : in std_logic;
					--	Stop      : in	std_logic;
						------------------------------
						--clock_out : out std_logic;
--						 interrupt_ack : out std_logic; --agregados
--						 read_strobe : out std_logic; -- agregados
                 btn_reset : in std_logic;
					  ext_reset : in std_logic;
						--	stop : in std_logic;
					  --Reset_contadores : in std_logic;
					  --Reset_Timers: in std_logic;
							-- RS 232 UART (DCE)
						uart_tx : out std_logic;
						uart_rx : in std_logic;					
							-- External Clock
							CLK_1HZ  : in std_logic;
                     clk_8Mhz : in std_logic;
							-- Output Clock
							CLK_100MHZ : out std_logic
		);
end Contador;

architecture Behavioral of Contador is


component clk_gen_100MHz is
port	( CLK_IN1           : in     std_logic;
		  CLK_OUT1          : out    std_logic
		);
end component;



signal clk 		: STD_LOGIC; --Señal para toda la logica, a 100 Mhz
signal not_clk : STD_LOGIC;

--
-- Declaration of the KCPSM6 component including default values for generics.
--

  component kcpsm6 
    generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                    interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
             scratch_pad_memory_size : integer := 64);
    port (                   address : out std_logic_vector(11 downto 0);
                         instruction : in std_logic_vector(17 downto 0);
                         bram_enable : out std_logic;
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      k_write_strobe : out std_logic;
                         read_strobe : out std_logic;
                           interrupt : in std_logic;
                       interrupt_ack : out std_logic;
                               sleep : in std_logic;
                               reset : in std_logic;
                                 clk : in std_logic);
  end component;



 component rom                            
--    generic(             C_FAMILY : string := "S6"; 
   --             C_RAM_SIZE_KWORDS : integer := 1;
   --          C_JTAG_LOADER_ENABLE : integer := 0);
    Port (      address : in std_logic_vector(11 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                 enable : in std_logic;
                    --rdl : out std_logic;                    
                    clk : in std_logic);
  end component;


--
-- UART Transmitter with integral 16 byte FIFO buffer
--

  component uart_tx6 
    Port (             data_in : in std_logic_vector(7 downto 0);
                  en_16_x_baud : in std_logic;
                    serial_out : out std_logic;
                  buffer_write : in std_logic;
           buffer_data_present : out std_logic;
              buffer_half_full : out std_logic;
                   buffer_full : out std_logic;
                  buffer_reset : in std_logic;
                           clk : in std_logic);
  end component;

--
-- UART Receiver with integral 16 byte FIFO buffer
--

  component uart_rx6 
    Port (           serial_in : in std_logic;
                  en_16_x_baud : in std_logic;
                      data_out : out std_logic_vector(7 downto 0);
                   buffer_read : in std_logic;
           buffer_data_present : out std_logic;
              buffer_half_full : out std_logic;
                   buffer_full : out std_logic;
                  buffer_reset : in std_logic;
                           clk : in std_logic);
  end component;



component Timer_64bit is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  enable : in STD_LOGIC;
			  --lee_dato : in STD_LOGIC;
			  frac_seg : out STD_LOGIC_VECTOR (31 downto 0);
           seg : out  STD_LOGIC_VECTOR (31 downto 0));
end component Timer_64bit;


	component Counter_32_bits is
		Port ( 
			  Pulse : in  STD_LOGIC;			
           Reset : in  STD_LOGIC;
			  Enable : in STD_LOGIC;
			  Count : out STD_LOGIC_VECTOR (31 downto 0)
			  );
   end component Counter_32_bits;


component Master_Control
			Port ( 
				clk : in  STD_LOGIC;
				Pulse_A : in  STD_LOGIC;
				Pulse_B : in  STD_LOGIC;				
				Reset : in  STD_LOGIC;
				Enable : in STD_LOGIC;
				Pulse_Max : in STD_LOGIC_VECTOR (31 downto 0);
				Timer_Max  : in STD_LOGIC_VECTOR (15 downto 0);
				Cnt_A_Enable : out STD_LOGIC;	
				Cnt_B_Enable : out STD_LOGIC;	-- Salida Contadores
				T1_Enable :	out STD_LOGIC;
				T2_Enable :	out STD_LOGIC	
				);						
end component Master_Control;


component debounce
  port(
		clk     : IN  STD_LOGIC;  --señal de reloj CLK
		button  : IN  STD_LOGIC;  --input
		result  : OUT STD_LOGIC
		); --output
end component debounce;	

--
-- Signals for connection of KCPSM6 and Program Memory.
--

signal         address : std_logic_vector(11 downto 0);
signal     instruction : std_logic_vector(17 downto 0);
signal     bram_enable : std_logic;
signal         in_port : std_logic_vector(7 downto 0);
signal        out_port : std_logic_vector(7 downto 0);
signal         port_id : std_logic_vector(7 downto 0);
signal    write_strobe : std_logic;
signal  k_write_strobe : std_logic;
signal     read_strobe : std_logic;
signal       interrupt : std_logic;
signal   interrupt_ack : std_logic;
signal    kcpsm6_sleep : std_logic;
signal    kcpsm6_reset : std_logic;

signal  r_write_strobe : std_logic;
--
-- Some additional signals are required if your system also needs to reset KCPSM6. 
--

signal       cpu_reset : std_logic;
signal             rdl : std_logic;

--
-- When interrupt is to be used then the recommended circuit included below requires 
-- the following signal to represent the request made from your system.
--

signal     int_request : std_logic;

--
-- Signals used to connect UART_TX6
--
signal      uart_tx_data_in : std_logic_vector(7 downto 0);
signal     write_to_uart_tx : std_logic;
signal uart_tx_data_present : std_logic;
signal    uart_tx_half_full : std_logic;
signal         uart_tx_full : std_logic;
signal         uart_tx_reset : std_logic := '0';
--
-- Signals used to connect UART_RX6
--
signal     uart_rx_data_out : std_logic_vector(7 downto 0);
signal    read_from_uart_rx : std_logic;
signal uart_rx_data_present : std_logic;
signal    uart_rx_half_full : std_logic;
signal         uart_rx_full : std_logic;
signal        uart_rx_reset : std_logic := '0';

signal uart_status_port : std_logic_vector(7 downto 0);

signal control_status_port : std_logic_vector (7 downto 0);
--
-- Signals used to define baud rate
--
signal           baud_count : integer range 0 to 107 := 0; 
signal         en_16_x_baud : std_logic := '0';


-- Señales del contador

signal test_clk_A                : std_logic;
signal test_clk_B                : std_logic;
-- Señales para el limite de tiempo y pulsos
signal Latch						: std_logic_vector (31 downto 0) :=X"00000000";
signal Latch_time					: std_logic_vector (15 downto 0) :=X"FFFF";
signal Latch_pulses 				: std_logic_vector (31 downto 0) :=X"FFFFFFFF";
signal Mode							: std_logic := '0'; --0 sera modo pulsos
-- Contadores A y B
signal a_count                 : std_logic_vector (31 downto 0) :=X"00000000";
signal b_count                 : std_logic_vector (31 downto 0) :=X"00000000";

-- Señales para conectar el timer_64_bits
signal enable_timer_T1		: std_logic := '0';
signal enable_timer_T2		: std_logic := '0';

signal Enable_Counter_A		: std_logic := '0';
signal Enable_Counter_B		: std_logic := '0';

signal control_busy: std_logic :='0';			-- señal de espera
signal control_error : std_logic :='0';		-- señal de error
signal error_counter	: integer range 0 to 5 := 0;

--signal lee_dato : std_logic:='0';
signal lee_segundo_T1 : std_logic_vector (31 downto 0);
signal lee_frac_segundo_T1 : std_logic_vector (31 downto 0);
signal lee_segundo_T2 : std_logic_vector (31 downto 0);
signal lee_frac_segundo_T2 : std_logic_vector (31 downto 0);
signal internal_reset : std_logic;


signal clk_buf : STD_LOGIC;

----- señales de aviso, start y stop -----------------
type estado_led is (encendido, apagado, Espera); 
signal D_bus, Q_bus : estado_led := Espera; -- lo inicializo en el estado apagado
---signal D_bus, Qbus :  std_logic;
signal reset : std_logic := '0';
signal input : std_logic_vector (1 downto 0) :="00";
-- señales de salida de datos
signal salida1_s : std_logic;
------------------------------------
--signal start_button : std_logic := '0';
--signal Start_logic : std_logic := '0'; -- boton start virtual

--signal Start : std_logic;
--signal Stop : std_logic;

-- señales para el control de las transmition gates
signal TG_signal : std_logic_vector (5 downto 0) := "000000";

-------------------------------------------------------------------------------------------------------------
-- señal contador de un hert sintetica
signal count :STD_LOGIC_VECTOR (25 downto 0):=(others => '0');-- integer :=0;
signal CLK_1HZs : std_logic := '0';

-- signals for read period
signal a_period : std_logic_vector (31 downto 0) :=X"00000000"; -- period  A
--signal a_prdtmp  : std_logic_vector (31 downto 0) :=X"00000000"; -- counter A

signal b_period : std_logic_vector (31 downto 0) :=X"00000000"; -- period  B
--signal b_prdtmp  : std_logic_vector (31 downto 0) :=(others => '0'); -- counter B

--signal for free run counter 42 seconds
signal Curr_Count	: std_logic_vector(31 downto 0):=(others => '0');
signal Prev_CountA : std_logic_vector(31 downto 0):=(others => '0');
signal Prev_CountB : std_logic_vector(31 downto 0):=(others => '0');

-------------------------------------------------------------------------------------------------------------
begin

--- junto las señales de los start y stop en un vector de entrada
--input <= Start & Stop;


CLK_GEN_1: clk_gen_100MHz 
port map ( 	CLK_IN1 => clk_8Mhz ,
				CLK_OUT1 => clk
			);

--clk <=clk_100mhz;

-- clk_50mhz: process(clk_100mhz)
--  begin
--    if rising_edge(clk_100mhz) then
--         clk <= not clk;
--    end if;
--  end process clk_50mhz;



processor: kcpsm6
    generic map (                 hwbuild => X"00", 
                         interrupt_vector => X"3FF",
                  scratch_pad_memory_size => 64)
    port map(      address => address,
               instruction => instruction,
               bram_enable => bram_enable,
                   port_id => port_id,
              write_strobe => r_write_strobe,
            k_write_strobe => k_write_strobe,
                  out_port => out_port,
               read_strobe => read_strobe,
                   in_port => in_port,
                 interrupt => interrupt,
             interrupt_ack => interrupt_ack,
                     sleep => kcpsm6_sleep,
                     reset => kcpsm6_reset,
                       clk => clk);


kcpsm6_reset <=  btn_reset or ext_reset; --'0'; --When using normal program ROM--
kcpsm6_sleep <= btn_reset;--'0';
interrupt <= interrupt_ack;
write_strobe <= k_write_strobe or r_write_strobe;





program_rom: rom                    --Name to match your PSM file
--    generic map(             C_FAMILY => "S6",   --Family 'S6', 'V6' or '7S'
    --                C_RAM_SIZE_KWORDS => 1,      --Program size '1', '2' or '4'
    --             C_JTAG_LOADER_ENABLE => 0)      --Include JTAG Loader when set to '1' 
    port map(      address => address,      
               instruction => instruction,
                    enable => bram_enable,
                      -- rdl => kcpsm6_reset,
                       clk => clk);




 -----------------------------------------------------------------------------------------
 -- UART Transmitter with integral 16 byte FIFO buffer
 -----------------------------------------------------------------------------------------
  u_tx: uart_tx6 
  port map (              data_in => uart_tx_data_in,
                     en_16_x_baud => en_16_x_baud,
                       serial_out => uart_tx,
                     buffer_write => write_to_uart_tx,
              buffer_data_present => uart_tx_data_present,
                 buffer_half_full => uart_tx_half_full,
                      buffer_full => uart_tx_full,
                     buffer_reset => uart_tx_reset,              
                              clk => clk);

  -----------------------------------------------------------------------------------------
  -- UART Receiver with integral 16 byte FIFO buffer
  -----------------------------------------------------------------------------------------
  u_rx: uart_rx6 
  port map (            serial_in => uart_rx,
                     en_16_x_baud => en_16_x_baud,
                         data_out => uart_rx_data_out,
                      buffer_read => read_from_uart_rx,
              buffer_data_present => uart_rx_data_present,
                 buffer_half_full => uart_rx_half_full,
                      buffer_full => uart_rx_full,
                     buffer_reset => uart_rx_reset,              
                              clk => clk);						  


  baud_timer: process(clk)
  begin
    if clk'event and clk='1' then
      if baud_count=107 then  -- cambio para adaptar al reloj de 89 a 81 -- 26 son 115200 baudios
           baud_count <= 0;
         en_16_x_baud <= '1';
       else
           baud_count <= baud_count + 1;
         en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_timer;


------------------------------------------------------------------------------------------------------
-- posible rolloever por monoware a 150mhz y 17 horas







------------------------------------------------------------------------------------------------------








-- Timer del patron
Timer_T1: Timer_64bit
		port map(
					clk => clk,
					reset => internal_reset, -- conecto temporalmente al enable
					enable =>	enable_timer_T1,
					--lee_dato => lee_dato,
					frac_seg => lee_frac_segundo_T1,
					seg => Lee_segundo_T1
					);
					
-- Timer del IBC					
Timer_T2: Timer_64bit
		port map(
					clk => clk,
					reset => internal_reset, -- conecto temporalmente al enable
					enable =>	enable_timer_T2,
					--lee_dato => lee_dato,
					frac_seg => lee_frac_segundo_T2,
					seg => Lee_segundo_T2
					);					
					
		-- Contador A es el Patron			
Contador_A : Counter_32_bits 
		Port map ( 
					Pulse => test_clk_A,			
					Reset =>  internal_reset,
					Enable => Enable_Counter_A,
					Count => a_count
					);
		  
		  --Contador B es IBC
Contador_B : Counter_32_bits 
		Port map ( 
					Pulse => test_clk_B,			
					Reset =>  internal_reset,
					Enable => Enable_Counter_B,
					Count => b_count
					);	  
			
		--Filtro Digital del Patron
Elimina_Rebotes_A : debounce
		port map(
					clk => clk,  --señal de reloj CLK
					button  => Pulsos_A,  --input
					result => test_clk_A
					); --output

		--Filtro Digital del IBC
Elimina_Rebotes_B : debounce
		port map(
					clk => clk,  --señal de reloj CLK
					button  => Pulsos_B,  --input
					result => test_clk_B
					); --output




Control: Master_Control
		Port map( 
				clk => clk,
				Pulse_A => test_clk_A,
				Pulse_B => test_clk_B,			
				Reset => internal_reset,
				Enable => salida1_s, --'0', --stop, --siempre , si presiono el boton se apaga.
				Pulse_Max => Latch_pulses(31 downto 0),		-- Limite de cuenta en pulsos
				Timer_Max => Latch_time(15 downto 0),		-- Limite de cuenta en Tiempo					
				Cnt_A_Enable =>	Enable_Counter_A,					-- Salida Contadores
				Cnt_B_Enable =>	Enable_Counter_B,	
				T1_Enable => enable_timer_T1,
				T2_Enable => enable_timer_T2	
				);





----------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM6 input ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- UART FIFO status signals to form a bus
  --
  uart_status_port <= "000" & uart_rx_data_present & uart_rx_full & uart_rx_half_full & uart_tx_full & uart_tx_half_full ;
  --
  -- The inputs connect via a pipelined multiplexer
  --
  ---------------------------------------------------------------------------------------------

  control_busy <= Enable_Counter_A or Enable_Counter_B;
  control_status_port <= "00000" & control_error & control_busy & salida1_s;
  ----------------------------------------------------------------------------------------------
  input_ports: process(clk)
  begin
    if rising_edge(clk) then--clk'event and clk='1' then

     case port_id(7 downto 0) is -- Se utilizan 8 bits de direcciones de entrada

-- Contador A en las direcciones 00, 01, 02 y 03 hexadecimales
        
		  when "00000000" =>    in_port <= a_count(7 downto 0);  
        when "00000001" =>    in_port <= a_count(15 downto 8);  
        when "00000010" =>    in_port <= a_count(23 downto 16);  
        when "00000011" =>    in_port <= a_count(31 downto 24);
-- Contador B en las direcciones 04, 05, 06 y 07 hexadecimales
		  when "00000100" =>    in_port <= b_count(7 downto 0);  
        when "00000101" =>    in_port <= b_count(15 downto 8);  
        when "00000110" =>    in_port <= b_count(23 downto 16);  
        when "00000111" =>    in_port <= b_count(31 downto 24);     

-- Hago las Lecturas del Timer 1 de 64 bits primero la parte fraccionaria, 08, 09, 0A, 0B
			when "00001000" => in_port <= lee_frac_segundo_T1(7 downto 0);  
			when "00001001" => in_port <= lee_frac_segundo_T1(15 downto 8);   
			when "00001010" => in_port <= lee_frac_segundo_T1(23 downto 16);   
			when "00001011" => in_port <= lee_frac_segundo_T1(31 downto 24);    
-- Hago las Lecturas del Timer 1 de 64 bits despues la parte entera,  0C, 0D, 0E, 0F		
			when "00001100" => in_port <= lee_segundo_T1(7 downto 0); 
			when "00001101" => in_port <= lee_segundo_T1(15 downto 8);  
			when "00001110" => in_port <= lee_segundo_T1(23 downto 16); 
			when "00001111" => in_port <= lee_segundo_T1(31 downto 24);  	
-- Hago las Lecturas del Timer 1 de 64 bits primero la parte fraccionaria, 18, 19, 1A, 1B
			when "00011000" => in_port <= lee_frac_segundo_T2(7 downto 0);  
			when "00011001" => in_port <= lee_frac_segundo_T2(15 downto 8);   
			when "00011010" => in_port <= lee_frac_segundo_T2(23 downto 16);   
			when "00011011" => in_port <= lee_frac_segundo_T2(31 downto 24);    
-- Hago las Lecturas del Timer 1 de 64 bits despues la parte entera,  1C, 1D, 1E, 1F		
			when "00011100" => in_port <= lee_segundo_T2(7 downto 0); 
			when "00011101" => in_port <= lee_segundo_T2(15 downto 8);  
			when "00011110" => in_port <= lee_segundo_T2(23 downto 16); 
			when "00011111" => in_port <= lee_segundo_T2(31 downto 24);  
---		20, 21, 22, 23
		   when "00100000" => in_port <= a_period(7 downto 0);	
			when "00100001" => in_port <= a_period(15 downto 8);  
			when "00100010" => in_port <= a_period(23 downto 16); 
			when "00100011" => in_port <= a_period(31 downto 24);  
			---		24, 25, 26, 27
		   when "00100100" => in_port <= b_period(7 downto 0);	
			when "00100101" => in_port <= b_period(15 downto 8);  
			when "00100110" => in_port <= b_period(23 downto 16); 
			when "00100111" => in_port <= b_period(31 downto 24);  
			
		-- read control status at address 3F hex
			when "00111111" => in_port <= control_status_port(7 downto 0);
		-- read UART status at address 40 hex, es decir el bit 6 en 1
			when "01000000" => in_port <= uart_status_port;
		-- read UART receive data at address 80 hex, es decir bit 7 en 1
			when "10000000" => in_port <= uart_rx_data_out;
-- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;
--------------------------------------------------------------------------------------	
		read_from_uart_rx <= read_strobe and port_id(7); --y el bit 7 es 1
--------------------------------------------------------------------------------------
     end if;

  end process input_ports;

----------------------------------------------------------------------------------------------------------------------------------
---		KCPSM6 output ports 
----------------------------------------------------------------------------------------------------------------------------------

-- 	adding the output registers to the processor
   
  output_ports: process(clk)
  begin

    if clk'event and clk='1' then
      if write_strobe='1' then



     case port_id(7 downto 0) is -- Se utilizan 8 bits de direcciones de entrada

-- Contador A en las direcciones 00, 01, 02 y 03 hexadecimales
        
		-- when "00000001" =>    Start_logic <= '0';--in_port <= a_count(7 downto 0);  
      	when "00000010" =>    input(1 downto 0) <= out_port(1 downto 0);
			--TG
			when "00000011" =>    TG_signal(5 downto 0) <= out_port(5 downto 0);
			when "00000100" =>    Latch_pulses(7 downto 0)   <= out_port(7 downto 0); 
			when "00000101" =>    Latch_pulses(15 downto 8)  <= out_port(7 downto 0);  
			when "00000110" => 	 Latch_pulses(23 downto 16) <= out_port(7 downto 0);
			when "00000111" => 	 Latch_pulses(31 downto 24) <= out_port(7 downto 0);		  
		   when "00001000" =>    Latch_time(7 downto 0)   <= out_port(7 downto 0); 
			when "00001001" =>    Latch_time(15 downto 8)  <= out_port(7 downto 0);  
--			when "00001110" => 	 Latch_pulses(23 downto 16) <= out_port(7 downto 0);
--			when "00001111" => 	 Latch_pulses(31 downto 24) <= out_port(7 downto 0);
--			
			
			when others =>    out_port <= "XXXXXXXX";  

      end case;
		
	
      end if;

    end if; 

  end process output_ports;

--
  -- Write directly to the FIFO buffer within 'uart_tx6' macro at port address 01 hex.
  -- Note the direct connection of 'out_port' to the UART transmitter macro and the 
  -- way that a single clock cycle write pulse is generated to capture the data.
  -- 

uart_tx_data_in <= out_port;

write_to_uart_tx  <= '1' when (write_strobe = '1') and (port_id(7) = '1')	-- 80
                           else '0'; 

internal_reset	<= '1' when (write_strobe = '1') and (port_id(6) = '1')		-- 40
                           else '0'; 

---------------------------------------------------------------------------------------

--
--------- Registro de Estado -------
process (clk, internal_reset)
begin
	if internal_reset='1' then   
			Q_bus <= Espera;
	 elsif clk'event and clk='1' then  
         Q_bus <= D_bus;
   end if;
end process;
--
--------- Lógica de Estado Siguiente -------
process (Q_bus,input)
begin
    case (Q_bus) is 
      when apagado =>
  				case (input) is 
				--	when "01" =>
					--	D_bus <= Espera;
					when others =>
						D_bus <= apagado;
				end case;
				
				
				
      when encendido =>
       	case (input) is 
					when "10" =>
						D_bus <= apagado;
					when others =>
						D_bus <= encendido;
				end case;
				
				
		when Espera =>
       	case (input) is 
					when "01" =>
						D_bus <= encendido;
					when others =>
						D_bus <= Espera;
				end case;		
			
   end case;			
end process;
--		
---------- Lógica de Salida de Maquina de estados de Moore --------
with Q_bus select
      salida1_s <= '0' when apagado,
						 '1' when encendido,
						 '0' when Espera,
						 '0' when others;
--					 
--					 
-------------- Otras Salidas---------------------------------------
----Led_aviso <= salida1_s;

---------------------------------------------------------------------------------------





--Latch_Time <= latch;
-----------------
uart_tx_reset <= '0';
uart_rx_reset <= '0';

-----------------------------------------------------------------------------------------
---- Agrego esto para evitar error de falta de pulsos
---- es un contador de segundos
-----------------------------------------------------------------------------------------
nopulse_timer: process(CLK_1HZ, salida1_s,internal_reset)
  begin  
  	if internal_reset='1' then   
			error_counter  <=  0;
			control_error  <= '0';
  
   elsif CLK_1HZ'event and CLK_1HZ='1' then
			if salida1_s='1' and error_counter >= 5 then
				  --error_counter  <= 0;
					control_error <= '1';
			elsif salida1_s='0' and error_counter < 5 then
					control_error <= '0';	-- si no esta en estart error es 0
			else
					error_counter  <= error_counter + 1;
					control_error  <= '0';
			end if;
   end if;

	 
  end process nopulse_timer;



------------- Agrego nueva señal de 1 hert ----------------------------------------------------------------------------------------------------
-- Genera un reloj de 1Hz a partir de un reloj de 100 MHz.
---------------------------------------------------------------------------------- 
process(clk)
begin
	if rising_edge(clk) then
		count <=count+1;
		if(count = 49999999) then ---49999999
			clk_1Hzs <= not clk_1Hzs;
			count <=(others => '0');--0;
		end if;
	end if;
end process;

--Increment Curr_Count every clock cycle.This is the max freq which can be measured by the module.
process(clk)
begin
	if( rising_edge(clk) ) then
		Curr_Count <= Curr_Count + 1; 
   end if; 
end process;

--Calculate the time period of the pulse input using the current and previous counts.
process(test_clk_A)
begin
    if( rising_edge(test_clk_A) ) then
    --These different conditions eliminate the count overflow problem
    --which can happen once the module is run for a long time.
       if( Prev_CountA < Curr_Count ) then
            a_period <= Curr_Count - Prev_CountA;
           -- ERR_O <= '0';
        elsif( Prev_CountA > Curr_Count ) then
        --X"F_F" is same as "1111_1111".
        --'_' is added for readability.
            a_period <= (X"FFFFFFFF" - Prev_CountA) + Curr_Count;     
           -- ERR_O <= '0';
        else
         a_period <= (others => '0');
            --ERR_O <= '1';  --Error bit is inserted here.
        end if;     
        Prev_CountA <= Curr_Count;  --Re-setting the Prev_Count. 
    end if; 
end process;


--Calculate the time period of the pulse input using the current and previous counts.
process(test_clk_B)
begin
    if( rising_edge(test_clk_B) ) then
    --These different conditions eliminate the count overflow problem
    --which can happen once the module is run for a long time.
       if( Prev_CountB < Curr_Count ) then
            b_period <= Curr_Count - Prev_CountB;
           -- ERR_O <= '0';
        elsif( Prev_CountB > Curr_Count ) then
        --X"F_F" is same as "1111_1111".
        --'_' is added for readability.
            b_period <= (X"FFFFFFFF" - Prev_CountB) + Curr_Count;     
           -- ERR_O <= '0';
        else
         b_period <= (others => '0');
            --ERR_O <= '1';  --Error bit is inserted here.
        end if;     
        Prev_CountB <= Curr_Count;  --Re-setting the Prev_Count. 
    end if; 
end process;



 ----------------------------------------------------------------------------------------------------------------------------------
 -- Salidas y Entradas Externas
 ---------------------------------------------------------------------------------------------------------------------------------

-- ODDR2: Output Double Data Rate Output Register with Set, Reset
-- and Clock Enable.
-- Spartan-6
-- Xilinx HDL Libraries Guide, version 13.4
ODDR2_inst : ODDR2
	generic map(
		DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
		INIT => '0', -- Sets initial state of the Q output to '0' or '1'
		SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
port map (
	Q => CLK_100MHZ , -- 1-bit output data
	C0 => clk, -- 1-bit clock input
	C1 => not_clk, -- 1-bit clock input
	CE => '1', -- 1-bit clock enable input
	D0 => '1', -- 1-bit data input (associated with C0)
	D1 => '0', -- 1-bit data input (associated with C1)
	R => '0', -- 1-bit reset input
	S => '0' -- 1-bit set input
);
-- End of ODDR2_inst instantiation										  
--											  
not_clk <= not clk;		
--
--
Enable_1 <= Enable_Counter_A;--Enable_timer_T1;
Enable_2 <= Enable_Counter_B;--Enable_timer_T2;
--
--
Led(0) 	<= Enable_Counter_A;--Enable_timer_T1;
Led(1) 	<= Enable_Counter_B;--Enable_timer_T2;
Led(2) 	<= clk_1hz; --control_error;
Led(3) 	<= salida1_s; 
Pin1 		<= CLK_1HZs;
Pin2 		<= not CLK_1HZs;
--
--
TG <= TG_signal;
--
end Behavioral;

