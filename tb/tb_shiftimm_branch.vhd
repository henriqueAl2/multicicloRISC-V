library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity tb_shiftimm_branch is
end entity tb_shiftimm_branch;

architecture sim of tb_shiftimm_branch is
    signal instr    : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal imm32    : signed(WORD_WIDTH-1 downto 0);
    signal alu_op   : std_logic_vector(1 downto 0) := (others => '0');
    signal alu_ctrl : std_logic_vector(3 downto 0);
    signal A, B     : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal rs2      : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal Z        : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal cond     : std_logic;
    signal zero     : std_logic;
begin
    imm: genImm32
        port map (
            instr => instr,
            imm32 => imm32
        );

    ctrl: controle_ula
        port map (
            alu_op_ctrl => alu_op,
            funct7_bit  => instr(30),
            funct3      => instr(14 downto 12),
            alu_ctrl    => alu_ctrl
        );

    uut: ulaRV
        generic map (
            WSIZE => WORD_WIDTH
        )
        port map (
            opcode => alu_ctrl,
            A      => A,
            B      => B,
            Z      => Z,
            cond   => cond,
            zero   => zero
        );

    -- S_I_EXEC: B = imediato / S_BRANCH: B = X[rs2]
    B <= std_logic_vector(imm32) when alu_op = "11" else rs2;

    process
    begin
        
        -- GRUPO SHIFT Imm 
        
        alu_op <= "11";
        A <= x"FF000000";

        -- srli t3, t2, 4 => 0x0FF00000
        instr <= x"0043de13";
        wait for 10 ns;
        assert Z = x"0FF00000"
            report "falha SRLi" severity failure;

        -- srai t4, t2, 4 => 0xFFF00000
        instr <= x"4043de93";
        wait for 10 ns;
        assert Z = x"FFF00000"
            report "falha SRAi" severity failure;

        -- slli t5, t2, 4 => 0xF0000000
        instr <= x"00439f13";
        wait for 10 ns;
        assert Z = x"F0000000"
            report "falha SLLi" severity failure;

        -- GRUPO BRANCH
        -- desvia quando zero = '1' nos casos de EscrevePCCond and zero

        alu_op <= "01";

        -- blt t0, zero, blton => 0 < 0 -> nao desvia
        instr <= x"0002c463";
        A <= x"00000000"; rs2 <= x"00000000";
        wait for 10 ns;
        assert zero = '0' and imm32 = 8
            report "falha BLT (0 < 0)" severity failure;

        -- blt t0, zero, blton => -1 < 0 -> desvia
        A <= x"FFFFFFFF"; rs2 <= x"00000000";
        wait for 10 ns;
        assert zero = '1'
            report "falha BLT (-1 < 0)" severity failure;

        -- bge t0, zero, bluton => -1 >= 0 -> nao desvia
        instr <= x"0002d663";
        A <= x"FFFFFFFF"; rs2 <= x"00000000";
        wait for 10 ns;
        assert zero = '0' and imm32 = 12
            report "falha BGE (-1 >= 0)" severity failure;

        -- bge t0, zero, bluton => 0 >= 0 -> desvia
        A <= x"00000000"; rs2 <= x"00000000";
        wait for 10 ns;
        assert zero = '1'
            report "falha BGE (0 >= 0)" severity failure;

        -- bltu x0, t0, bgeuton => 0 <u 0 -> nao desvia
        instr <= x"00506663";
        A <= x"00000000"; rs2 <= x"00000000";
        wait for 10 ns;
        assert zero = '0' and imm32 = 12
            report "falha BLTU (0 <u 0)" severity failure;

        -- bltu x0, t0, bgeuton => 0 <u 0xFFFFFFFF -> desvia
        A <= x"00000000"; rs2 <= x"FFFFFFFF";
        wait for 10 ns;
        assert zero = '1'
            report "falha BLTU (0 <u 0xFFFFFFFF)" severity failure;

        -- bgeu t1, t0, bgeuton => 1000 >=u 0xFFFFFFFF -> nao desvia (offset -4)
        instr <= x"fe537ee3";
        A <= x"000003E8"; rs2 <= x"FFFFFFFF";
        wait for 10 ns;
        assert zero = '0' and imm32 = -4
            report "falha BGEU (1000 >=u 0xFFFFFFFF)" severity failure;

        -- bgeu t0, t1, FOI => 0xFFFFFFFF >=u 1000 -> desvia
        instr <= x"0062f463";
        A <= x"FFFFFFFF"; rs2 <= x"000003E8";
        wait for 10 ns;
        assert zero = '1' and imm32 = 8
            report "falha BGEU (0xFFFFFFFF >=u 1000)" severity failure;

        report "todos os testes de shift Imm e branch passaram" severity note;
        wait;
    end process;
end architecture sim;
