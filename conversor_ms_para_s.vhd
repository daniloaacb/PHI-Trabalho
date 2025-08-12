library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity conversor_ms_para_s is
  generic (
    MAX_MS : natural := 2000   --
  );
  port (
    rtempo_ms : in  std_logic_vector(11 downto 0); -- 12 bits
    s_int     : out std_logic_vector(1 downto 0);  -- segundos inteiros
    s_milli   : out std_logic_vector(9 downto 0)   -- milissegundos (0..999)
  );
end conversor_ms_para_s;

architecture comb of conversor_ms_para_s is
  constant MS_PER_S : unsigned(11 downto 0) := to_unsigned(1000, 12);
  signal ms_in      : unsigned(11 downto 0);
  signal ms_sat     : unsigned(11 downto 0);
  signal q_sec      : unsigned(11 downto 0);
  signal r_ms       : unsigned(11 downto 0);
begin
  ms_in <= unsigned(rtempo_ms);

  -- Saturação em MAX_MS (evita mostrar >2.000 ms se esse for o requisito)
  ms_sat <= (others => '0') when MAX_MS = 0 else
            (others => '1') when ms_in > to_unsigned(MAX_MS, 12) and MAX_MS > 4095 else
            (ms_in) when ms_in <= to_unsigned(MAX_MS, 12) else
            to_unsigned(MAX_MS, 12);

  -- Divisão por constante
  q_sec <= ms_sat / MS_PER_S;  -- quociente = segundos
  r_ms  <= ms_sat mod MS_PER_S; -- resto = milissegundos

  -- Redimensiona para as larguras de saída
  s_int   <= std_logic_vector(resize(q_sec, 2));
  s_milli <= std_logic_vector(resize(r_ms, 10));
end comb;
