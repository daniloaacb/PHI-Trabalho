library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temporizador_10s is
  port (
    clk        : in  std_logic;  -- 2,5 kHz
    rst        : in  std_logic;  -- reset assíncrono, nível alto
    pronto_10s : out std_logic   -- vai a '1' após 10 s e permanece até novo reset
  );
end temporizador_10s;

architecture rtl of temporizador_10s is
  -- 10 s * 2.500 Hz = 25.000 ciclos
  constant MAX_COUNT : natural := 25000;

  -- 0 .. 24.999 cabe em 15 bits (2^15 = 32768)
  signal count : unsigned(14 downto 0) := (others => '0');
  signal ready : std_logic := '0';
begin
  pronto_10s <= ready;

  process (clk, rst)
  begin
    if rst = '1' then
      count <= (others => '0');
      ready <= '0';
    elsif rising_edge(clk) then
      if ready = '0' then              -- só conta até completar os 10 s
        if count = to_unsigned(MAX_COUNT - 1, count'length) then
          ready <= '1';                -- atingiu 10 s
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
