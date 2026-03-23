library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scadere is
    Port (
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        a      : in  STD_LOGIC_VECTOR(31 downto 0);
        b      : in  STD_LOGIC_VECTOR(31 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0);
        ready  : out STD_LOGIC
    );
end scadere;

architecture Behavioral of scadere is
    signal b_neg : STD_LOGIC_VECTOR(31 downto 0);
begin
    -- -b = flip sign bit
    b_neg <= (not b(31)) & b(30 downto 0);

    U_ADD: entity work.adunare_fast
        port map(
            clk    => clk,
            reset  => reset,
            a      => a,
            b      => b_neg,
            result => result,
            ready  => ready
        );
end Behavioral;