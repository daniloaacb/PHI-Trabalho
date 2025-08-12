library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Controle simples da lâmpada:
-- len = 0 enquanto pronto_10s = 0
-- quando pronto_10s = 1, len é setado para 1 e permanece até rst
entity controle_lampada is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;   -- reset assíncrono ativo em '1'
    pronto_10s : in  std_logic;   -- vindo do temporizador de 10 s
    len        : out std_logic    -- habilitação da lâmpada
  );
end controle_lampada;

architecture rtl of controle_lampada is
  signal len_r : std_logic := '0';
begin
  len <= len_r;

  process (clk, rst)
  begin
    if rst = '1' then
      len_r <= '0';
    elsif rising_edge(clk) then
      -- Lógica tipo "latch set síncrono": uma vez pronto_10s=1, acende e mantém
      if pronto_10s = '1' then
        len_r <= '1';
      end if;
    end if;
  end process;
end rtl;
