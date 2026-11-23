library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity ulaRV is
    generic (
        WSIZE : natural := WORD_WIDTH
    );
    port (
        opcode : in  std_logic_vector(3 downto 0);
        A      : in  std_logic_vector(WORD_WIDTH-1 downto 0);
        B      : in  std_logic_vector(WORD_WIDTH-1 downto 0);
        Z      : out std_logic_vector(WORD_WIDTH-1 downto 0);
        cond   : out std_logic;
        zero   : out std_logic
    );
end entity ulaRV;

architecture Behavioral of ulaRV is
    signal a32 : std_logic_vector(WORD_WIDTH-1 downto 0);
begin

    Z    <= a32;
    zero <= '1' when a32 = x"00000000" else '0';

    proc_ula: process(A, B, opcode)
    begin
        cond <= '0';

        case opcode is
            when ALU_ADD =>
                a32 <= std_logic_vector(signed(A) + signed(B));

            when ALU_SUB =>
                a32 <= std_logic_vector(signed(A) - signed(B));

            when ALU_AND =>
                a32 <= A and B;

            when ALU_OR =>
                a32 <= A or B;

            when ALU_XOR =>
                a32 <= A xor B;

            when ALU_SLL =>
                a32 <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B(4 downto 0)))));

            when ALU_SRL =>
                a32 <= std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0)))));

            when ALU_SRA =>
                a32 <= std_logic_vector(shift_right(signed(A), to_integer(unsigned(B(4 downto 0)))));

            when ALU_SLT =>
                if signed(A) < signed(B) then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when ALU_SLTU =>
                if unsigned(A) < unsigned(B) then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when ALU_SGE =>
                if signed(A) >= signed(B) then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when ALU_SGEU =>
                if unsigned(A) >= unsigned(B) then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when ALU_SEQ =>
                if A = B then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when ALU_SNE =>
                if A /= B then
                    cond <= '1';
                    a32  <= x"00000001";
                else
                    cond <= '0';
                    a32  <= x"00000000";
                end if;

            when others =>
                a32  <= (others => '0');
                cond <= '0';
        end case;
    end process proc_ula;

end architecture Behavioral;