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

architecture Behavioral of controle_ula is
begin
    process(alu_op_ctrl, funct7_bit, funct3)
    begin
        case alu_op_ctrl is
            when "00" =>
                alu_ctrl <= "0000"; -- ADD

            when "01" =>
                case funct3 is
                    when "000"  => alu_ctrl <= "0001"; -- BEQ -> SUB
                    when "001"  => alu_ctrl <= "1100"; -- BNE -> SEQ
                    when "100"  => alu_ctrl <= "1010"; -- BLT -> SGE
                    when "101"  => alu_ctrl <= "1000"; -- BGE -> SLT
                    when "110"  => alu_ctrl <= "1011"; -- BLTU -> SGEU
                    when "111"  => alu_ctrl <= "1001"; -- BGEU -> SLTU
                    when others => alu_ctrl <= "0001";
                end case;

            when "10" =>
                case funct3 is
                    when "000" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= "0001"; -- SUB
                        else
                            alu_ctrl <= "0000"; -- ADD
                        end if;
                    when "001"  => alu_ctrl <= "0101"; -- SLL
                    when "010"  => alu_ctrl <= "1000"; -- SLT
                    when "011"  => alu_ctrl <= "1001"; -- SLTU
                    when "100"  => alu_ctrl <= "0100"; -- XOR
                    when "101" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= "0111"; -- SRA
                        else
                            alu_ctrl <= "0110"; -- SRL
                        end if;
                    when "110"  => alu_ctrl <= "0011"; -- OR
                    when "111"  => alu_ctrl <= "0010"; -- AND
                    when others => alu_ctrl <= "0000";
                end case;

            when "11" =>
                case funct3 is
                    when "000"  => alu_ctrl <= "0000"; -- ADDI
                    when "001"  => alu_ctrl <= "0101"; -- SLLI
                    when "010"  => alu_ctrl <= "1000"; -- SLTI
                    when "011"  => alu_ctrl <= "1001"; -- SLTIU
                    when "100"  => alu_ctrl <= "0100"; -- XORI
                    when "101" =>
                        if funct7_bit = '1' then
                            alu_ctrl <= "0111"; -- SRAI
                        else
                            alu_ctrl <= "0110"; -- SRLI
                        end if;
                    when "110"  => alu_ctrl <= "0011"; -- ORI
                    when "111"  => alu_ctrl <= "0010"; -- ANDI
                    when others => alu_ctrl <= "0000";
                end case;

            when others =>
                alu_ctrl <= "0000";
        end case;
    end process;
end architecture Behavioral;