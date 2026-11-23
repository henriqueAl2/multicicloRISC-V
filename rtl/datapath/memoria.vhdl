library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity memoria is
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
end entity memoria;

architecture Behavioral of memoria is
    type ram_t is array (0 to DEPTH-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    signal mem       : ram_t := (others => (others => '0'));
    signal word_addr : integer range 0 to DEPTH-1;
begin

    word_addr <= to_integer(unsigned(endereco(9 downto 2)));

    process(clk)
    begin
        if rising_edge(clk) then
            if escreveMem = '1' then
                mem(word_addr) <= dado_in;
            end if;
        end if;
    end process;

    dado_out <= mem(word_addr) when leMem = '1' else (others => '0');

end architecture Behavioral;