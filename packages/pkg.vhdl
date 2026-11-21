library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is

    --Constantes de configuração do processador. Um define o tamanho da arquitetura, o outro define os endereços dos registradores e o último define a profundidade da memória.
    constant WORD_WIDTH : natural := 32;
    constant REG_ADDR_W : natural := 5;
    constant MEM_DEPTH  : natural := 256;

    --Opcode das instruções
    constant OP_R_TYPE  : std_logic_vector(6 downto 0) := "0110011";
    constant OP_I_ALU   : std_logic_vector(6 downto 0) := "0010011";
    constant OP_LOAD    : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE   : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH  : std_logic_vector(6 downto 0) := "1100011";
    constant OP_JAL     : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR    : std_logic_vector(6 downto 0) := "1100111";
    constant OP_LUI     : std_logic_vector(6 downto 0) := "0110111";

    --Controle da ULA
    constant ALU_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND    : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR     : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR    : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SLL    : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL    : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA    : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SLT    : std_logic_vector(3 downto 0) := "1000";
    constant ALU_SLTU   : std_logic_vector(3 downto 0) := "1001";
    constant ALU_SGE    : std_logic_vector(3 downto 0) := "1010";
    constant ALU_SGEU   : std_logic_vector(3 downto 0) := "1011";
    constant ALU_SEQ    : std_logic_vector(3 downto 0) := "1100";
    constant ALU_SNE    : std_logic_vector(3 downto 0) := "1101";

    type reg_array_t is array (0 to 31) of std_logic_vector(WORD_WIDTH-1 downto 0);
    type mem_array_t is array (0 to MEM_DEPTH-1) of std_logic_vector(WORD_WIDTH-1 downto 0);

    component reg_en is --registradores intermediários com enable
        generic (
            WIDTH : natural := WORD_WIDTH
        );
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            en    : in  std_logic;
            dado     : in  std_logic_vector(WIDTH-1 downto 0); 
            q     : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component XREGS is --banco de registradores
        generic (
            WSIZE : natural := WORD_WIDTH
        );
        port (
            clk, wren    : in  std_logic; --wren = escreve no registrador
            rs1, rs2, rd : in  std_logic_vector(REG_ADDR_W-1 downto 0);
            data         : in  std_logic_vector(WSIZE-1 downto 0);
            ro1, ro2     : out std_logic_vector(WSIZE-1 downto 0)
        );
    end component;

    component genImm32 is --gerador de imediato de 32 bits
        port (
            instr : in  std_logic_vector(WORD_WIDTH-1 downto 0);
            imm32 : out signed(WORD_WIDTH-1 downto 0)
        );
    end component;

    component ulaRV is 
        generic (
            WSIZE : natural := WORD_WIDTH
        );
        port (
            opcode : in  std_logic_vector(3 downto 0);
            A, B   : in  std_logic_vector(WSIZE-1 downto 0);
            Z      : out std_logic_vector(WSIZE-1 downto 0);
            cond   : out std_logic;
            zero   : out std_logic
        );
    end component;

    component controle_ula is
        port (
            alu_op_ctrl : in  std_logic_vector(1 downto 0);
            funct7_bit  : in  std_logic;
            funct3      : in  std_logic_vector(2 downto 0);
            alu_ctrl    : out std_logic_vector(3 downto 0)
        );
    end component;

    component memoria is
        generic (
            DEPTH : natural := MEM_DEPTH
        );
        port (
            clk        : in  std_logic;
            escreveMem : in  std_logic;
            leMem      : in  std_logic;
            endereco   : in  std_logic_vector(WORD_WIDTH-1 downto 0);
            dado_in    : in  std_logic_vector(WORD_WIDTH-1 downto 0);
            dado_out   : out std_logic_vector(WORD_WIDTH-1 downto 0)
        );
    end component;

    component controle is
        port (
            clk            : in  std_logic;
            rst            : in  std_logic;
            opcode         : in  std_logic_vector(6 downto 0);
            EscrevePCCond  : out std_logic;
            EscrevePC      : out std_logic;
            IouD           : out std_logic;
            EscreveMem     : out std_logic;
            LeMem          : out std_logic;
            EscreveIR      : out std_logic;
            Mem2Reg        : out std_logic_vector(1 downto 0);
            OrigPC         : out std_logic;
            ALUOp          : out std_logic_vector(1 downto 0);
            OrigAULA       : out std_logic_vector(1 downto 0);
            OrigBULA       : out std_logic_vector(1 downto 0);
            EscrevePCB     : out std_logic;
            EscreveReg     : out std_logic
        );
    end component;

end package pkg;