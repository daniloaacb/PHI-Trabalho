library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_fsm_top is
end tb_fsm_top;

architecture sim of tb_fsm_top is
    -- Sinais para DUT
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal B      : std_logic := '0';
    signal len    : std_logic;
    signal rtempo : std_logic_vector(11 downto 0);
    signal lento  : std_logic;

    -- Clock 2,5 kHz
    constant clk_period : time := 400 us;  -- 400 µs → 2,5 kHz
begin

    -- Instancia o DUT
    uut: entity work.fsm_top
        port map (
            clk    => clk,
            rst    => rst,
            B      => B,
            len    => len,
            rtempo => rtempo,
            lento  => lento
        );

    -- Processo de geração de clock
    clk_process : process
    begin
        while now < 30 sec loop  -- Simula por até 30 segundos
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Processo de estímulos
    stim_proc : process
    begin
        --------------------------------------------------------------------
        -- Reset inicial
        --------------------------------------------------------------------
        rst <= '1';
        wait for 2 ms; -- alguns ciclos
        rst <= '0';

        --------------------------------------------------------------------
        -- CENÁRIO 1: Usuário rápido (500 ms após lâmpada acender)
        --------------------------------------------------------------------
        report "Esperando 10 segundos para acender a lâmpada..." severity note;
        wait until len = '1';  -- Espera lâmpada acender
        wait for 500 ms;       -- Reação rápida
        B <= '1';
        wait for 200 ms;   -- 1 ciclo de clock
        B <= '0';


        -- Espera sistema voltar ao reset
        wait for 2 sec;
		  wait for clk_period;
		  rst <= '1';
		  wait for 100 ms;
		  rst <= '0';

        --------------------------------------------------------------------
        -- CENÁRIO 2: Usuário lento (> 2 s sem apertar botão)
        --------------------------------------------------------------------
        report "Esperando 10 segundos para acender a lâmpada..." severity note;
        wait until len = '1';  -- Espera lâmpada acender
        wait for 3 sec;        -- Espera além do limite
        wait for 2 sec;

        --------------------------------------------------------------------
        -- Finaliza simulação
        --------------------------------------------------------------------
        report "Fim da simulação" severity note;
        wait;
    end process;

end sim;
