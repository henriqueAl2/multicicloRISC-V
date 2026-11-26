library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity riscv_multiciclo_tb is
end entity riscv_multiciclo_tb;

architecture Behavioral of riscv_multiciclo_tb is
    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    constant CLK_PERIOD : time := 10 ns;
    signal parar : boolean := false;
    signal instr, dado_escrita, endereco, reg_b : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal EscreveReg, EscreveMem : std_logic;

    -- escritas esperadas no banco de registradores, em ordem (programas/teste_multiciclo.asm)
    type escrita_t is record
        rd    : natural;
        valor : std_logic_vector(WORD_WIDTH-1 downto 0);
    end record;
    type escritas_t is array (natural range <>) of escrita_t;
    constant ESPERADO : escritas_t := (
        -- núcleo comum
        (10, x"00002000"), -- auipc a0,0x2
        (11, x"00002004"), -- auipc a1,0x2
        ( 8, x"00002000"), -- lui s0,0x2
        ( 9, x"0000000F"), -- lw s1,0(s0)
        (18, x"0000003F"), -- lw s2,4(s0)
        (19, x"0000004E"), -- add s3,s1,s2
        (10, x"0000004E"), -- lw a0,8(s0)
        (20, x"000007F0"), -- addi s4,zero,2032
        (21, x"000000FF"), -- addi s5,zero,255
        (22, x"000000F0"), -- and s6,s5,s4
        (23, x"000007FF"), -- or s7,s5,s4
        (24, x"0000070F"), -- xor s8,s5,s4
        ( 5, x"FFFFFFFF"), -- addi t0,zero,-1
        ( 6, x"00000001"), -- addi t1,zero,1
        ( 8, x"00000001"), -- slt s0,t0,t1
        ( 9, x"00000000"), -- slt s1,t1,t0
        (18, x"FFFFFFFE"), -- sub s2,t0,t1
        (19, x"00000002"), -- sub s3,t1,t0
        ( 1, x"00000050"), -- jal ra,testasub
        (28, x"FFFFFFFE"), -- sub t3,t0,t1
        ( 5, x"FFFFFFFE"), -- addi t0,zero,-2
        ( 5, x"00000000"), -- addi t0,t0,2
        ( 5, x"00000002"), -- addi t0,t0,2
        ( 5, x"00000001"), -- addi t0,t0,-1
        ( 5, x"00000000"), -- addi t0,t0,-1
        -- grupo imm
        (10, x"000000FF"), -- ori a0,zero,255
        (11, x"000000F0"), -- andi a1,a0,240
        (12, x"FFFFFF00"), -- xori a2,a0,-1
        (13, x"000007FF"), -- ori a3,a1,2047
        -- grupo comp
        ( 5, x"FFFFFFFF"), -- addi t0,zero,-1
        ( 6, x"00000001"), -- addi t1,zero,1
        ( 8, x"00000000"), -- slti s0,zero,-1
        ( 9, x"00000001"), -- slti s1,zero,1
        (18, x"00000000"), -- slti s2,t0,-1
        (19, x"00000001"), -- sltu s3,t1,t0
        (20, x"00000000"), -- sltu s4,t0,t1
        (21, x"00000001"), -- sltiu s5,t1,-1
        -- grupo shift
        ( 7, x"FF000000"), -- lui t2,0xff000
        (10, x"00000004"), -- addi a0,zero,4
        (28, x"0FF00000"), -- srl t3,t2,a0
        (29, x"FFF00000"), -- sra t4,t2,a0
        (30, x"F0000000"), -- sll t5,t2,a0
        -- grupo shift imm
        ( 7, x"FF000000"), -- lui t2,0xff000
        (28, x"0FF00000"), -- srli t3,t2,0x4
        (29, x"FFF00000"), -- srai t4,t2,0x4
        (30, x"F0000000"), -- slli t5,t2,0x4
        -- grupo branch
        ( 5, x"00000001"), -- addi t0,zero,1
        ( 5, x"00000000"), -- addi t0,t0,-1
        ( 5, x"FFFFFFFF"), -- addi t0,t0,-1
        ( 5, x"00000000"), -- addi t0,t0,1
        ( 5, x"FFFFFFFF"), -- addi t0,t0,-1
        ( 6, x"000003E8")  -- addi t1,zero,1000
    );

    type nomes_t is array (0 to 31) of string(1 to 4);
    constant NOMES : nomes_t := (
        "zero", "ra  ", "sp  ", "gp  ", "tp  ", "t0  ", "t1  ", "t2  ",
        "s0  ", "s1  ", "a0  ", "a1  ", "a2  ", "a3  ", "a4  ", "a5  ",
        "a6  ", "a7  ", "s2  ", "s3  ", "s4  ", "s5  ", "s6  ", "s7  ",
        "s8  ", "s9  ", "s10 ", "s11 ", "t3  ", "t4  ", "t5  ", "t6  ");
begin

    -- Instanciação do Processador (DUT)
    DUT : entity work.riscv_multiciclo
        port map (
            clk             => clk_tb,
            rst             => rst_tb,
            ir_out          => instr,
            escreve_reg_out => EscreveReg,
            dado_reg_out    => dado_escrita,
            escreve_mem_out => EscreveMem,
            endereco_out    => endereco,
            dado_mem_out    => reg_b
        );

    -- Geração contínua do Clock
    clk_tb <= not clk_tb after CLK_PERIOD / 2 when not parar;

    -- Estímulo de Reset Inicial
    process
    begin
        rst_tb <= '1';
        wait for 20 ns;
        rst_tb <= '0';
        wait until parar for 20 us;
        assert parar
            report "falha: o programa nao chegou no fim em 20 us" severity failure;
        wait;
    end process;

    -- confere cada escrita no banco de registradores e na memória
    verifica: process
        variable rd    : natural;
        variable k     : natural := 0;
        variable sw_ok : boolean := false;
    begin
        wait until rising_edge(clk_tb);
        if rst_tb = '0' then
            rd := to_integer(unsigned(instr(11 downto 7)));

            if EscreveReg = '1' and rd /= 0 then
                report NOMES(rd) & " <= 0x" & to_hstring(dado_escrita);
                assert k <= ESPERADO'high
                    report "falha: escrita a mais em " & NOMES(rd) severity failure;
                assert rd = ESPERADO(k).rd and dado_escrita = ESPERADO(k).valor
                    report "falha na escrita " & integer'image(k + 1) & ": " & NOMES(rd) & " <= 0x" & to_hstring(dado_escrita)
                         & " (esperado " & NOMES(ESPERADO(k).rd) & " <= 0x" & to_hstring(ESPERADO(k).valor) & ")"
                    severity failure;
                k := k + 1;
            end if;

            -- sw s3, 8(s0) => mem[0x2008] <= 78
            if EscreveMem = '1' then
                report "mem[0x" & to_hstring(endereco) & "] <= 0x" & to_hstring(reg_b);
                assert endereco = x"00002008" and reg_b = x"0000004E"
                    report "falha sw: esperado mem[0x00002008] <= 0x0000004e" severity failure;
                sw_ok := true;
            end if;

            -- fim: j fim
            if instr = x"0000006F" then
                assert k = ESPERADO'length
                    report "falha: so " & integer'image(k) & " de " & integer'image(ESPERADO'length) & " escritas" severity failure;
                assert sw_ok
                    report "falha sw: nenhuma escrita na memoria" severity failure;
                report "todos os testes do processador passaram com sucesso! (" & integer'image(k) & " escritas conferidas)";
                parar <= true;
                wait;
            end if;
        end if;
    end process;

end architecture Behavioral;
