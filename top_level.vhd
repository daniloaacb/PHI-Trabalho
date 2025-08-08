library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level do sistema: apenas instancia o bloco de controle (FSM)
-- e repassa as I/Os conforme o enunciado.
entity top_level is
  port (
    clk    : in  std_logic;                       -- 2,5 kHz
    rst    : in  std_logic;                       -- reset assíncrono ativo em '1'
    B      : in  std_logic;                       -- botão (assume-se debounced)
    len    : out std_logic;                       -- habilitação da lâmpada
    rtempo : out std_logic_vector(11 downto 0);   -- tempo de reação em ms (12 bits)
    lento  : out std_logic                        -- 1 se usuário demorou > 2 s
  );
end top_level;

architecture rtl of top_level is
begin
  -- O módulo controle_reacao já instancia:
  --   - temporizador_10s
  --   - controle_lampada
  --   - contador_tempo_reacao
  -- e coordena tudo via FSM.
  u_ctrl : entity work.controle_reacao
    port map (
      clk    => clk,
      rst    => rst,
      B      => B,
      len    => len,
      rtempo => rtempo,
      lento  => lento
    );

end rtl;
