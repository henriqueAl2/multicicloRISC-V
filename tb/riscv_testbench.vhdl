library ieee;
use ieee.std_logic_1164.all;

entity riscv_multiciclo_tb is
end entity riscv_multiciclo_tb;

architecture Behavioral of riscv_multiciclo_tb is
    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    constant CLK_PERIOD : time := 10 ns;
begin

    -- Instanciação do Processador (DUT)
    DUT : entity work.riscv_multiciclo
        port map (
            clk => clk_tb,
            rst => rst_tb
        );

    -- Geração contínua do Clock
    clk_tb <= not clk_tb after CLK_PERIOD / 2;

    -- Estímulo de Reset Inicial
    process
    begin
        rst_tb <= '1';
        wait for 20 ns;
        rst_tb <= '0';
        wait for 1000 ns;
        wait;
    end process;

end architecture Behavioral;