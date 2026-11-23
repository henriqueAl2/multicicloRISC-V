-- Banco de registradores do processador
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity XREGS is
    generic (
        WSIZE : natural := WORD_WIDTH
    );
    port (
        clk, wren    : in  std_logic;
        rs1, rs2, rd : in  std_logic_vector(REG_ADDR_W-1 downto 0);
        data         : in  std_logic_vector(WSIZE-1 downto 0);
        ro1, ro2     : out std_logic_vector(WSIZE-1 downto 0)
    );
end entity XREGS;

architecture Behavioral of XREGS is
    type breg_t is array (0 to (2**REG_ADDR_W)-1) of std_logic_vector(WSIZE-1 downto 0);
    signal breg : breg_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if wren = '1' and unsigned(rd) /= 0 then
                breg(to_integer(unsigned(rd))) <= data;
            end if;
        end if;
    end process;

    ro1 <= (others => '0') when unsigned(rs1) = 0 else breg(to_integer(unsigned(rs1)));
    ro2 <= (others => '0') when unsigned(rs2) = 0 else breg(to_integer(unsigned(rs2)));
end architecture Behavioral;