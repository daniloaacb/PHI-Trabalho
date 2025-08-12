library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity contador_tempo_reacao is
  generic (
    US_PER_TICK : natural := 400;   -- 2,5 kHz -> 400 us por tick
    MAX_MS      : natural := 2000   -- timeout = 2000 ms (2 s)
  );
  port (
    clk    : in  std_logic;                       -- 2,5 kHz
    rst    : in  std_logic;                       -- reset 
    start  : in  std_logic;                       -- sobe para iniciar
    B      : in  std_logic;                       -- botão
    rtempo : out std_logic_vector(11 downto 0);   -- tempo
    lento  : out std_logic;                       -- 1 se excedeu 2 s sem apertar
    done   : out std_logic                        -- 1 quando medir terminou
  );
end contador_tempo_reacao;

architecture rtl of contador_tempo_reacao is
  -- Acumulador de microssegundos: precisa acomodar até 1000 + US_PER_TICK
  signal us_acc      : unsigned(10 downto 0) := (others => '0');

  -- Contador de milissegundos (12 bits para rtempo 0..4095)
  signal ms_count    : unsigned(11 downto 0) := (others => '0');

  -- Estado interno
  signal counting    : std_logic := '0';  -- 1 enquanto medindo
  signal lento_r     : std_logic := '0';
  signal done_r      : std_logic := '0';

  -- Detecção de borda de subida em start
  signal start_d     : std_logic := '0';
begin
  rtempo <= std_logic_vector(ms_count);
  lento  <= lento_r;
  done   <= done_r;

  process (clk, rst)
    variable add_us    : unsigned(10 downto 0);
    variable sub_1000  : unsigned(10 downto 0);
  begin
    if rst = '1' then
      us_acc   <= (others => '0');
      ms_count <= (others => '0');
      counting <= '0';
      lento_r  <= '0';
      done_r   <= '0';
      start_d  <= '0';
    elsif rising_edge(clk) then
      -- amostra anterior de start para detectar subida
      start_d <= start;

      if (done_r = '0') then
        -- Inicia contagem ao detectar borda de subida de start
        if (counting = '0') and (start_d = '0') and (start = '1') then
          counting <= '1';
          -- zera contadores no início de uma nova medição
          us_acc   <= (others => '0');
          ms_count <= (others => '0');
          lento_r  <= '0';
        end if;
      end if;

      if (counting = '1') and (done_r = '0') then
        -- Se botão foi pressionado, finaliza medição
        if B = '1' then
          counting <= '0';
          done_r   <= '1';
        else
          -- Avança o tempo: soma 400 us a cada tick e transforma em ms
          add_us   := us_acc + to_unsigned(US_PER_TICK, us_acc'length);
          if add_us >= to_unsigned(1000, us_acc'length) then
            -- Gera +1 ms e subtrai 1000 us do acumulador
            sub_1000 := add_us - to_unsigned(1000, us_acc'length);
            us_acc   <= sub_1000;

            -- Incrementa ms, com saturação em MAX_MS
            if ms_count < to_unsigned(MAX_MS, ms_count'length) then
              ms_count <= ms_count + 1;
            end if;

            -- Timeout: atingiu 2000 ms antes do botão
            if (ms_count + 1) = to_unsigned(MAX_MS, ms_count'length) then
              lento_r  <= '1';
              counting <= '0';
              done_r   <= '1';
            end if;
          else
            -- Ainda não completou 1 ms, apenas acumula us
            us_acc <= add_us;
          end if;
        end if;
      end if;
    end if;
  end process;
end rtl;
