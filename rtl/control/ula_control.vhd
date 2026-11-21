library ieee;
use ieee.std_logic_1164.all;
use work.pkg.all;

entity controle_ula is
    port (
        alu_op_ctrl : in  std_logic_vector(1 downto 0);
        funct7_bit  : in  std_logic; -- bit 30 da instrucao: instr(30)
        funct3      : in  std_logic_vector(2 downto 0); -- bits 14..12 da instrucao
        alu_ctrl    : out std_logic_vector(3 downto 0)
    );
end entity controle_ula;

architecture rtl of controle_ula is
begin
    process(alu_op_ctrl, funct7_bit, funct3)
    begin
        -- Padrao seguro
        alu_ctrl <= ALU_ADD;

        case alu_op_ctrl is
            -- Tipo R (OP_R_TYPE = "0110011"): SLTU, SLL, SRL, SRA
            when "10" =>
                case funct3 is
                    when "001" => -- SLL
                        alu_ctrl <= ALU_SLL;

                    when "011" => -- SLTU
                        alu_ctrl <= ALU_SLTU;

                    when "101" => -- SRL (funct7_bit = '0') ou SRA (funct7_bit = '1')
                        if funct7_bit = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;

                    when others =>
                        alu_ctrl <= ALU_ADD;
                end case;

            -- Tipo I ULA (OP_I_ALU = "0010011"): SLTi, SLTIU
            when "11" =>
                case funct3 is
                    when "010" => -- SLTi
                        alu_ctrl <= ALU_SLT;

                    when "011" => -- SLTIU
                        alu_ctrl <= ALU_SLTU;

                    when others =>
                        alu_ctrl <= ALU_ADD;
                end case;

            when others =>
                alu_ctrl <= ALU_ADD;
        end case;
    end process;
end architecture rtl;