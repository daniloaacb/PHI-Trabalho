library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_top is
  port (
    clk    : in  std_logic;                       -- 2,5 kHz
    rst    : in  std_logic;                       -- reset 
    B      : in  std_logic;                       -- botão 
    len    : out std_logic;                       -- habilita lâmpada
    rtempo : out std_logic_vector(11 downto 0);   -- tempo de reação
    lento  : out std_logic                        -- usuario lento
  );
end fsm_top;

architecture rtl of fsm_top is

  ---------------------------------------------------------------------------
  -- Declaração de componentes
  ---------------------------------------------------------------------------
  component temporizador_10s is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      pronto_10s : out std_logic
    );
  end component;

  component controle_lampada is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      pronto_10s : in  std_logic;
      len        : out std_logic
    );
  end component;

  component contador_tempo_reacao is
    generic (
      US_PER_TICK : natural := 400;
      MAX_MS      : natural := 2000
    );
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      start  : in  std_logic;
      B      : in  std_logic;
      rtempo : out std_logic_vector(11 downto 0);
      lento  : out std_logic;
      done   : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Sinais internos
  ---------------------------------------------------------------------------
  signal pronto_10s  : std_logic := '0';
  signal len_i       : std_logic := '0';
  signal start_pulse : std_logic := '0';
  signal done_i      : std_logic := '0';
  signal lento_i     : std_logic := '0';
  signal rtempo_i    : std_logic_vector(11 downto 0) := (others => '0');
  signal pronto_d    : std_logic := '0';

    ---------------------------------------------------------------------------
  -- FSM
  ---------------------------------------------------------------------------
  type state_t is (WAIT_10S, ARM_START, MEASURE, HOLD_DONE);
  signal state, next_state : state_t := WAIT_10S;

begin
  -- Saídas externas
  len    <= len_i;
  lento  <= lento_i;
  rtempo <= rtempo_i;

  ---------------------------------------------------------------------------
  -- Instância: temporizador de 10 s
  ---------------------------------------------------------------------------
  u_t10s : temporizador_10s
    port map (
      clk        => clk,
      rst        => rst,
      pronto_10s => pronto_10s
    );

  ---------------------------------------------------------------------------
  -- Instância: controle da lâmpada
  ---------------------------------------------------------------------------
  u_lamp : controle_lampada
    port map (
      clk        => clk,
      rst        => rst,
      pronto_10s => pronto_10s,
      len        => len_i
    );

  ---------------------------------------------------------------------------
  -- Instância: contador de tempo de reação
  ---------------------------------------------------------------------------
  u_ctr : contador_tempo_reacao
    generic map (
      US_PER_TICK => 400,   -- 2,5 kHz → 400 us por tick
      MAX_MS      => 2000
    )
    port map (								
      clk    => clk,	  					
      rst    => rst,						
      start  => start_pulse,			
      B      => B,						  
      rtempo => rtempo_i,				
      lento  => lento_i,				
      done   => done_i 
    );

  ---------------------------------------------------------------------------
  -- end 10 segundos
  ---------------------------------------------------------------------------
  process (clk, rst)
  begin
    if rst = '1' then
      pronto_d <= '0';
    elsif rising_edge(clk) then
      pronto_d <= pronto_10s;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Lógica da FSM
  ---------------------------------------------------------------------------
  process (clk, rst)
  begin
    if rst = '1' then
      state       <= WAIT_10S;
      start_pulse <= '0';
    elsif rising_edge(clk) then
      state       <= next_state;
      if next_state = ARM_START then
        start_pulse <= '1';
      else
        start_pulse <= '0';
      end if;
    end if;
  end process;

  process (state, pronto_10s, pronto_d, done_i)
  begin
    case state is
      when WAIT_10S =>
        if (pronto_d = '0' and pronto_10s = '1') then
          next_state <= ARM_START;
        else
          next_state <= WAIT_10S;
        end if;

      when ARM_START =>
        next_state <= MEASURE;

      when MEASURE =>
        if done_i = '1' then
          next_state <= HOLD_DONE;
        else
          next_state <= MEASURE;
        end if;

      when HOLD_DONE =>
        next_state <= HOLD_DONE;

      when others =>
        next_state <= WAIT_10S;
    end case;
  end process;

end rtl;
