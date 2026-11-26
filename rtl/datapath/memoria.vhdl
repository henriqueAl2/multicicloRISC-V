library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
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

    -- programa gerado pelo rars (dump memory, "hexadecimal text"): código a partir de 0x0000 e dados a partir de 0x2000
    constant ARQ_CODIGO : string := "programas/codigo.txt";
    constant ARQ_DADOS  : string := "programas/dados.txt";

    impure function carrega(ram_ini : ram_t; nome : string; inicio : natural) return ram_t is
        file arq      : text;
        variable st   : file_open_status;
        variable lin  : line;
        variable pal  : std_logic_vector(WORD_WIDTH-1 downto 0);
        variable ram  : ram_t := ram_ini;
        variable i    : natural := inicio;
    begin
        file_open(st, arq, nome, read_mode);
        if st /= open_ok then
            report "memoria: nao abriu " & nome severity warning;
            return ram;
        end if;
        while not endfile(arq) and i < DEPTH loop
            readline(arq, lin);
            if lin'length >= 8 then
                hread(lin, pal);
                ram(i) := pal;
                i := i + 1;
            end if;
        end loop;
        file_close(arq);
        return ram;
    end function;

    signal mem       : ram_t := carrega(carrega((others => (others => '0')), ARQ_CODIGO, 0), ARQ_DADOS, 16#2000# / 4);
    signal word_addr : integer range 0 to DEPTH-1;
begin

    word_addr <= to_integer(unsigned(endereco(13 downto 2)));

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
