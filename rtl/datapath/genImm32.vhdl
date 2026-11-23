library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity genImm32 is
    port (
        instr : in  std_logic_vector(WORD_WIDTH-1 downto 0);
        imm32 : out signed(WORD_WIDTH-1 downto 0)
    );
end entity genImm32;

architecture Behavioral of genImm32 is
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
begin
    opcode <= instr(6 downto 0);
    funct3 <= instr(14 downto 12);

    process(instr, opcode, funct3)
        variable res : std_logic_vector(31 downto 0);
    begin
        res := (others => '0');

        case opcode is
            when OP_R_TYPE =>
                res := (others => '0');

            when OP_LOAD | OP_JALR =>
                res(11 downto 0)  := instr(31 downto 20);
                res(31 downto 12) := (others => instr(31));

            when OP_I_ALU =>
                if funct3 = "101" and instr(30) = '1' then
                    res(4 downto 0)  := instr(24 downto 20);
                    res(31 downto 5) := (others => '0');
                else
                    res(11 downto 0)  := instr(31 downto 20);
                    res(31 downto 12) := (others => instr(31));
                end if;

            when OP_STORE =>
                res(4 downto 0)   := instr(11 downto 7);
                res(11 downto 5)  := instr(31 downto 25);
                res(31 downto 12) := (others => instr(31));

            when OP_BRANCH =>
                res(0)            := '0';
                res(4 downto 1)   := instr(11 downto 8);
                res(10 downto 5)  := instr(30 downto 25);
                res(11)           := instr(7);
                res(31 downto 12) := (others => instr(31));

            when OP_LUI | OP_AUIPC =>
                res(11 downto 0)  := (others => '0');
                res(31 downto 12) := instr(31 downto 12);

            when OP_JAL =>
                res(0)            := '0';
                res(10 downto 1)  := instr(30 downto 21);
                res(11)           := instr(20);
                res(19 downto 12) := instr(19 downto 12);
                res(31 downto 20) := (others => instr(31));

            when others =>
                res := (others => '0');
        end case;

        imm32 <= signed(res);
    end process;
end architecture Behavioral;