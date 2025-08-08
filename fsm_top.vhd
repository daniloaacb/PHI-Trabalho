library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top de controle: coordena temporização inicial, acende lâmpada e mede o tempo de reação.
entity controle_reacao is
  port (
    clk    : in  std_logic;                       -- 2,5 kHz
    rst    : in  std_logic;                       -- reset assíncrono ativo em '1'
    B      : in  std_logic;                       -- botão (assume-se debounced)
    len    : out std_logic;                       -- habilita lâmpada
    rtempo : out std_logic_vector(11 downto 0);   -- tempo de reação em ms (0..4095)
    lento  : out std_logic                        -- 1 se usuário demorou > 2 s
  );
end controle_reacao;

architecture rtl of controle_reacao is
  -- Sinais internos
  signal pronto_10s  : std_logic := '0';
  signal len_i       : std_logic := '0';

  -- Interconexão com o contador
  signal start_pulse : std_logic := '0';
  signal done_i      : std_logic := '0';
  signal lento_i     : std_logic := '0';
  signal rtempo_i    : std_logic_vector(11 downto 0) := (others => '0');

  -- Edge detect de pronto_10s (usado pela FSM)
  signal pronto_d    : std_logic := '0';

  -- FSM
  type state_t is (WAIT_10S, ARM_START, MEASURE, HOLD_DONE);
  signal state, next_state : state_t := WAIT_10S;

begin
  -- Saídas externas
  len    <= len_i;
  lento  <= lento_i;
  rtempo <= rtempo_i;

  ---------------------------------------------------------------------------
  -- Instância: temporizador de 10 s (clk=2,5 kHz → 25.000 ciclos)
  ---------------------------------------------------------------------------
  u_t10s : entity work.temporizador_10s
    port map (
      clk        => clk,
      rst        => rst,
      pronto_10s => pronto_10s
    );

  ---------------------------------------------------------------------------
  -- Instância: controle da lâmpada (liga e mantém após os 10 s, até rst)
  ---------------------------------------------------------------------------
  u_lamp : entity work.controle_lampada
    port map (
      clk        => clk,
      rst        => rst,
      pronto_10s => pronto_10s,
      len        => len_i
    );

  ---------------------------------------------------------------------------
  -- Instância: contador de tempo de reação (ms)
  -- - start_pulse: 1 ciclo quando a lâmpada acende
  -- - B: botão do usuário
  -- - lento_i/done_i/rtempo_i: resultados da medição
  ---------------------------------------------------------------------------
  u_ctr : entity work.contador_tempo_reacao
    generic map (
      US_PER_TICK => 400,   -- 2,5 kHz → 400 us por tick
      MAX_MS      => 2000   -- timeout em 2 s
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
  -- Edge detect de pronto_10s (amostra anterior)
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
  -- FSM: gera start_pulse quando a lâmpada acende e aguarda término
  ---------------------------------------------------------------------------
  -- Estado
  process (clk, rst)
  begin
    if rst = '1' then
      state       <= WAIT_10S;
      start_pulse <= '0';
    elsif rising_edge(clk) then
      state       <= next_state;

      -- Pulso de start: garantimos apenas 1 ciclo em ARM_START
      if next_state = ARM_START then
        start_pulse <= '1';
      else
        start_pulse <= '0';
      end if;
    end if;
  end process;

  -- Próximo estado
  process (state, pronto_10s, pronto_d, done_i)
  begin
    case state is
      when WAIT_10S =>
        -- Espera a borda de subida de pronto_10s (acabaram os 10 s)
        if (pronto_d = '0' and pronto_10s = '1') then
          next_state <= ARM_START;
        else
          next_state <= WAIT_10S;
        end if;

      when ARM_START =>
        -- Emite start_pulse por 1 ciclo e vai medir
        next_state <= MEASURE;

      when MEASURE =>
        -- Aguarda fim da medição (botão ou timeout)
        if done_i = '1' then
          next_state <= HOLD_DONE;
        else
          next_state <= MEASURE;
        end if;

      when HOLD_DONE =>
        -- Mantém resultados até novo reset
        next_state <= HOLD_DONE;

      when others =>
        next_state <= WAIT_10S;
    end case;
  end process;

end rtl;
