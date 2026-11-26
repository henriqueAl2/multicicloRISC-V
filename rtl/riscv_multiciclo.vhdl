-- processador risc-v multiciclo (figura 1 do projeto)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity riscv_multiciclo is
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        -- saídas de observação para o testbench
        ir_out          : out std_logic_vector(WORD_WIDTH-1 downto 0);
        escreve_reg_out : out std_logic;
        dado_reg_out    : out std_logic_vector(WORD_WIDTH-1 downto 0);
        escreve_mem_out : out std_logic;
        endereco_out    : out std_logic_vector(WORD_WIDTH-1 downto 0);
        dado_mem_out    : out std_logic_vector(WORD_WIDTH-1 downto 0)
    );
end entity riscv_multiciclo;

architecture Behavioral of riscv_multiciclo is
    -- sinais de controle
    signal EscrevePCCond, EscrevePC, IouD, EscreveMem, LeMem, EscreveIR : std_logic;
    signal OrigPC, EscrevePCB, EscreveReg : std_logic;
    signal Mem2Reg, ALUOp, OrigAULA, OrigBULA : std_logic_vector(1 downto 0);

    -- parte operativa
    signal pc, pc_back, pc_prox, endereco  : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal dado_mem, instr, reg_dado_mem   : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal ro1, ro2, reg_a, reg_b          : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal dado_escrita                    : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal imm32                           : signed(WORD_WIDTH-1 downto 0);
    signal ula_a, ula_b, ula_z, saida_ula  : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal alu_ctrl                        : std_logic_vector(3 downto 0);
    signal ula_cond, ula_zero, escreve_pc  : std_logic;
begin

    u_controle: controle
        port map (
            clk           => clk,
            rst           => rst,
            opcode        => instr(6 downto 0),
            EscrevePCCond => EscrevePCCond,
            EscrevePC     => EscrevePC,
            IouD          => IouD,
            EscreveMem    => EscreveMem,
            LeMem         => LeMem,
            EscreveIR     => EscreveIR,
            Mem2Reg       => Mem2Reg,
            OrigPC        => OrigPC,
            ALUOp         => ALUOp,
            OrigAULA      => OrigAULA,
            OrigBULA      => OrigBULA,
            EscrevePCB    => EscrevePCB,
            EscreveReg    => EscreveReg
        );

    -- pc: escrito incondicionalmente ou no desvio quando a ula dá zero
    escreve_pc <= EscrevePC or (EscrevePCCond and ula_zero);

    -- origpc: 0 = saída direta da ula (pc+4), 1 = saidaula (destino de desvio/salto)
    -- bit 0 zerado para o jalr (nos outros destinos ele já é 0)
    pc_prox <= ula_z when OrigPC = '0' else saida_ula(WORD_WIDTH-1 downto 1) & '0';

    r_pc: reg_en
        port map (clk => clk, rst => rst, en => escreve_pc, d => pc_prox, q => pc);

    r_pc_back: reg_en
        port map (clk => clk, rst => rst, en => EscrevePCB, d => pc, q => pc_back);

    -- ioud: 0 = pc (instrução), 1 = saidaula (dado)
    endereco <= pc when IouD = '0' else saida_ula;

    u_mem: memoria
        port map (
            clk        => clk,
            escreveMem => EscreveMem,
            leMem      => LeMem,
            endereco   => endereco,
            dado_in    => reg_b,
            dado_out   => dado_mem
        );

    r_ir: reg_en
        port map (clk => clk, rst => rst, en => EscreveIR, d => dado_mem, q => instr);

    r_dado_mem: reg_en
        port map (clk => clk, rst => rst, en => '1', d => dado_mem, q => reg_dado_mem);

    -- mem2reg: 00 = saidaula, 01 = pc (pc+4 para jal/jalr), 10 = dado da memória
    with Mem2Reg select
        dado_escrita <= saida_ula    when "00",
                        pc           when "01",
                        reg_dado_mem when others;

    u_xregs: XREGS
        port map (
            clk  => clk,
            wren => EscreveReg,
            rs1  => instr(19 downto 15),
            rs2  => instr(24 downto 20),
            rd   => instr(11 downto 7),
            data => dado_escrita,
            ro1  => ro1,
            ro2  => ro2
        );

    r_a: reg_en
        port map (clk => clk, rst => rst, en => '1', d => ro1, q => reg_a);

    r_b: reg_en
        port map (clk => clk, rst => rst, en => '1', d => ro2, q => reg_b);

    u_imm: genImm32
        port map (instr => instr, imm32 => imm32);

    -- origaula: 00 = pc, 01 = a, 10 = pcback, 11 = zero (lui)
    with OrigAULA select
        ula_a <= pc              when "00",
                 reg_a           when "01",
                 pc_back         when "10",
                 (others => '0') when others;

    -- origbula: 00 = b, 01 = 4, 10 e 11 = imediato
    -- sem o <<1 da figura: o genimm32 já entrega o offset em bytes
    with OrigBULA select
        ula_b <= reg_b                      when "00",
                 x"00000004"                when "01",
                 std_logic_vector(imm32)    when others;

    u_ctrl_ula: controle_ula
        port map (
            alu_op_ctrl => ALUOp,
            funct7_bit  => instr(30),
            funct3      => instr(14 downto 12),
            alu_ctrl    => alu_ctrl
        );

    u_ula: ulaRV
        port map (
            opcode => alu_ctrl,
            A      => ula_a,
            B      => ula_b,
            Z      => ula_z,
            cond   => ula_cond,
            zero   => ula_zero
        );

    r_saida_ula: reg_en
        port map (clk => clk, rst => rst, en => '1', d => ula_z, q => saida_ula);

    ir_out          <= instr;
    escreve_reg_out <= EscreveReg;
    dado_reg_out    <= dado_escrita;
    escreve_mem_out <= EscreveMem;
    endereco_out    <= endereco;
    dado_mem_out    <= reg_b;

end architecture Behavioral;
