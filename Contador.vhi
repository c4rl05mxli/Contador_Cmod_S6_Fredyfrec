
-- VHDL Instantiation Created from source file Contador.vhd -- 09:18:34 02/10/2017
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT Contador
	PORT(
		Pulsos_A : IN std_logic;
		Pulsos_B : IN std_logic;
		btn_reset : IN std_logic;
		uart_rx : IN std_logic;
		clk_8Mhz : IN std_logic;          
		led : OUT std_logic_vector(3 downto 0);
		Enable_1 : OUT std_logic;
		Enable_2 : OUT std_logic;
		uart_tx : OUT std_logic
		);
	END COMPONENT;

	Inst_Contador: Contador PORT MAP(
		led => ,
		Pulsos_A => ,
		Pulsos_B => ,
		Enable_1 => ,
		Enable_2 => ,
		btn_reset => ,
		uart_tx => ,
		uart_rx => ,
		clk_8Mhz => 
	);


