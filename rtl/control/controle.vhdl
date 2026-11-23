library ieee;
use ieee.std_logic_1164.all;
use work.pkg.all;

entity controle is
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
end entity controle;

architecture Behavioral of controle is
    type state_t is (
        S_FETCH,
        S_DECODE,
        S_MEM_ADDR,
        S_MEM_READ,
        S_MEM_WB,
        S_MEM_WRITE,
        S_R_EXEC,
        S_I_EXEC,
        S_ALU_WB,
        S_BRANCH,
        S_JAL,
        S_JALR_CALC,
        S_JALR_WB,
        S_LUI,
        S_AUIPC
    );

    signal state, next_state : state_t;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S_FETCH;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    process(state, opcode)
    begin
        case state is
            when S_FETCH =>
                next_state <= S_DECODE;

            when S_DECODE =>
                case opcode is
                    when "0000011" => next_state <= S_MEM_ADDR;  -- LW
                    when "0100011" => next_state <= S_MEM_ADDR;  -- SW
                    when "0110011" => next_state <= S_R_EXEC;    -- R-Type
                    when "0010011" => next_state <= S_I_EXEC;    -- I-ALU
                    when "1100011" => next_state <= S_BRANCH;    -- Branch
                    when "1101111" => next_state <= S_JAL;       -- JAL
                    when "1100111" => next_state <= S_JALR_CALC; -- JALR
                    when "0110111" => next_state <= S_LUI;       -- LUI
                    when "0010111" => next_state <= S_AUIPC;     -- AUIPC
                    when others    => next_state <= S_FETCH;
                end case;

            when S_MEM_ADDR =>
                if opcode = "0000011" then
                    next_state <= S_MEM_READ;
                else
                    next_state <= S_MEM_WRITE;
                end if;

            when S_MEM_READ =>
                next_state <= S_MEM_WB;

            when S_MEM_WB | S_MEM_WRITE | S_ALU_WB | S_BRANCH | S_JAL | S_JALR_WB =>
                next_state <= S_FETCH;

            when S_R_EXEC | S_I_EXEC | S_LUI | S_AUIPC =>
                next_state <= S_ALU_WB;

            when S_JALR_CALC =>
                next_state <= S_JALR_WB;

            when others =>
                next_state <= S_FETCH;
        end case;
    end process;

    process(state)
    begin
        EscrevePCCond <= '0';
        EscrevePC     <= '0';
        IouD          <= '0';
        EscreveMem    <= '0';
        LeMem         <= '0';
        EscreveIR     <= '0';
        Mem2Reg       <= "00";
        OrigPC        <= '0';
        ALUOp         <= "00";
        OrigAULA      <= "00";
        OrigBULA      <= "00";
        EscrevePCB    <= '0';
        EscreveReg    <= '0';

        case state is
            when S_FETCH =>
                LeMem      <= '1';
                EscreveIR  <= '1';
                IouD       <= '0';
                OrigAULA   <= "00";
                OrigBULA   <= "01";
                ALUOp      <= "00";
                OrigPC     <= '0';
                EscrevePC  <= '1';
                EscrevePCB <= '1';

            when S_DECODE =>
                OrigAULA <= "10";
                OrigBULA <= "11";
                ALUOp    <= "00";

            when S_MEM_ADDR =>
                OrigAULA <= "01";
                OrigBULA <= "10";
                ALUOp    <= "00";

            when S_MEM_READ =>
                LeMem <= '1';
                IouD  <= '1';

            when S_MEM_WB =>
                Mem2Reg    <= "10";
                EscreveReg <= '1';

            when S_MEM_WRITE =>
                EscreveMem <= '1';
                IouD       <= '1';

            when S_R_EXEC =>
                OrigAULA <= "01";
                OrigBULA <= "00";
                ALUOp    <= "10";

            when S_I_EXEC =>
                OrigAULA <= "01";
                OrigBULA <= "10";
                ALUOp    <= "11";

            when S_ALU_WB =>
                Mem2Reg    <= "00";
                EscreveReg <= '1';

            when S_BRANCH =>
                OrigAULA      <= "01";
                OrigBULA      <= "00";
                ALUOp         <= "01";
                OrigPC        <= '1';
                EscrevePCCond <= '1';

            when S_JAL =>
                Mem2Reg    <= "01";
                EscreveReg <= '1';
                OrigPC     <= '1';
                EscrevePC  <= '1';

            when S_JALR_CALC =>
                OrigAULA <= "01";
                OrigBULA <= "10";
                ALUOp    <= "00";

            when S_JALR_WB =>
                Mem2Reg    <= "01";
                EscreveReg <= '1';
                OrigPC     <= '1';
                EscrevePC  <= '1';

            when S_LUI =>
                OrigAULA <= "01";
                OrigBULA <= "10";
                ALUOp    <= "00";

            when S_AUIPC =>
                OrigAULA <= "10";
                OrigBULA <= "10";
                ALUOp    <= "00";

            when others =>
                null;
        end case;
    end process;

end architecture Behavioral;