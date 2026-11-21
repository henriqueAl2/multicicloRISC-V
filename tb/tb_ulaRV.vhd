library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity tb_ulaRV is
end entity tb_ulaRV;

architecture sim of tb_ulaRV is
    signal opcode : std_logic_vector(3 downto 0) := (others => '0');
    signal A, B   : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal Z      : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal cond   : std_logic;
    signal zero   : std_logic;
begin
    uut: ulaRV
        generic map (
            WSIZE => WORD_WIDTH
        )
        port map (
            opcode => opcode,
            A      => A,
            B      => B,
            Z      => Z,
            cond   => cond,
            zero   => zero
        );

    process
    begin
        -- =========================
        -- GRUPO COMP (Teste_multiciclo.asm)
        -- =========================

        -- slti s0, x0, -1  => 0 <s -1 -> 0
        opcode <= ALU_SLT;
        A <= x"00000000";
        B <= x"FFFFFFFF";
        wait for 10 ns;
        assert Z = x"00000000" and zero = '1' and cond = '0'
            report "Falha SLTi (0 < -1)" severity error;

        -- slti s1, x0, 1   => 0 <s 1 -> 1
        A <= x"00000000";
        B <= x"00000001";
        wait for 10 ns;
        assert Z = x"00000001" and zero = '0' and cond = '1'
            report "Falha SLTi (0 < 1)" severity error;

        -- slti s2, t0, -1  => -1 <s -1 -> 0
        A <= x"FFFFFFFF";
        B <= x"FFFFFFFF";
        wait for 10 ns;
        assert Z = x"00000000" and zero = '1' and cond = '0'
            report "Falha SLTi (-1 < -1)" severity error;

        -- sltu s3, t1, t0  => 1 <u 0xFFFFFFFF -> 1
        opcode <= ALU_SLTU;
        A <= x"00000001";
        B <= x"FFFFFFFF";
        wait for 10 ns;
        assert Z = x"00000001" and zero = '0' and cond = '1'
            report "Falha SLTU (1 <u -1)" severity error;

        -- sltu s4, t0, t1  => 0xFFFFFFFF <u 1 -> 0
        A <= x"FFFFFFFF";
        B <= x"00000001";
        wait for 10 ns;
        assert Z = x"00000000" and zero = '1' and cond = '0'
            report "Falha SLTU (-1 <u 1)" severity error;

        -- sltiu s5, t1, -1 => 1 <u 0xFFFFFFFF -> 1
        A <= x"00000001";
        B <= x"FFFFFFFF";
        wait for 10 ns;
        assert Z = x"00000001" and zero = '0' and cond = '1'
            report "Falha SLTIU (1 <u -1)" severity error;

        -- =========================
        -- GRUPO SHIFT (Teste_multiciclo.asm: t2 = 0xFF000000, a0 = 4)
        -- =========================

        -- srl t3, t2, a0 => 0x0FF00000
        opcode <= ALU_SRL;
        A <= x"FF000000";
        B <= x"00000004";
        wait for 10 ns;
        assert Z = x"0FF00000" and zero = '0'
            report "Falha SRL" severity error;

        -- sra t4, t2, a0 => 0xFFF00000
        opcode <= ALU_SRA;
        A <= x"FF000000";
        B <= x"00000004";
        wait for 10 ns;
        assert Z = x"FFF00000" and zero = '0'
            report "Falha SRA" severity error;

        -- sll t5, t2, a0 => 0xF0000000
        opcode <= ALU_SLL;
        A <= x"FF000000";
        B <= x"00000004";
        wait for 10 ns;
        assert Z = x"F0000000" and zero = '0'
            report "Falha SLL" severity error;

        report "Todos os testes de Comp e Shift passaram com sucesso!" severity note;
        wait;
    end process;
end architecture sim;