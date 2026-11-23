library ieee;
use ieee.std_logic_1164.all;
use work.pkg.all;

entity controle_ula is
    port (
        alu_op_ctrl : in  std_logic_vector(1 downto 0);
        funct7_bit  : in  std_logic;
        funct3      : in  std_logic_vector(2 downto 0);
        alu_ctrl    : out std_logic_vector(3 downto 0)
    );
end entity controle_ula;

architecture rtl of controle_ula is
begin
    process(alu_op_ctrl, funct7_bit, funct3)
    begin
        alu_ctrl <= ALU_ADD;

        case alu_op_ctrl is
            when "00" =>
                alu_ctrl <= ALU_ADD;

            when "01" =>
                case funct3 is
                    when "000" => alu_ctrl <= ALU_SUB;
                    when "001" => alu_ctrl <= ALU_SNE;
                    when "100" => alu_ctrl <= ALU_SGE;
                    when "101" => alu_ctrl <= ALU_SLT;
                    when "110" => alu_ctrl <= ALU_SGEU;
                    when "111" => alu_ctrl <= ALU_SLTU;
                    when others => alu_ctrl <= ALU_SUB;
                end case;

            when "10" =>
                case funct3 is
                    when "000" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= ALU_SUB;
                        else
                            alu_ctrl <= ALU_ADD;
                        end if;
                    when "001" => alu_ctrl <= ALU_SLL;
                    when "010" => alu_ctrl <= ALU_SLT;
                    when "011" => alu_ctrl <= ALU_SLTU;
                    when "100" => alu_ctrl <= ALU_XOR;
                    when "101" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when "110" => alu_ctrl <= ALU_OR;
                    when "111" => alu_ctrl <= ALU_AND;
                    when others => alu_ctrl <= ALU_ADD;
                end case;

            when "11" =>
                case funct3 is
                    when "000" => alu_ctrl <= ALU_ADD;
                    when "001" => alu_ctrl <= ALU_SLL;
                    when "010" => alu_ctrl <= ALU_SLT;
                    when "011" => alu_ctrl <= ALU_SLTU;
                    when "100" => alu_ctrl <= ALU_XOR;
                    when "101" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when "110" => alu_ctrl <= ALU_OR;
                    when "111" => alu_ctrl <= ALU_AND;
                    when others => alu_ctrl <= ALU_ADD;
                end case;

            when others => alu_ctrl <= ALU_ADD;
        end case;
    end process;
end architecture rtl;