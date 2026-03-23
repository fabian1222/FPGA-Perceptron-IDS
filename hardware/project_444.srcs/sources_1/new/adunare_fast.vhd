library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adunare_fast is
    Port (
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        a      : in  STD_LOGIC_VECTOR(31 downto 0);
        b      : in  STD_LOGIC_VECTOR(31 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0);
        ready  : out STD_LOGIC 
    );
end adunare_fast;

architecture Behavioral of adunare_fast is
    
    signal r_a, r_b : std_logic_vector(31 downto 0);
    
    
    function lzc27(v : unsigned(26 downto 0)) return integer is
    begin
        for i in 26 downto 0 loop
            if v(i) = '1' then return 26 - i; end if;
        end loop;
        return 27;
    end function;

begin
    process(clk)
        
        variable sa, sb, s_res : std_logic;
        variable ea, eb : unsigned(7 downto 0);
        variable ma, mb : unsigned(26 downto 0);
        variable diff : integer;
        variable m_big, m_small : unsigned(26 downto 0);
        variable e_big : integer;
        variable sum : unsigned(27 downto 0);
        variable lz : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                result <= (others => '0');
                ready <= '0';
            else
               
                sa := a(31); sb := b(31);
                ea := unsigned(a(30 downto 23));
                eb := unsigned(b(30 downto 23));
                
                if ea = 0 then ma := unsigned("0" & a(22 downto 0) & "000"); else ma := unsigned("1" & a(22 downto 0) & "000"); end if;
                if eb = 0 then mb := unsigned("0" & b(22 downto 0) & "000"); else mb := unsigned("1" & b(22 downto 0) & "000"); end if;

                if ea >= eb then
                    diff := to_integer(ea - eb);
                    e_big := to_integer(ea);
                    m_big := ma; m_small := shift_right(mb, diff);
                    s_res := sa;
                else
                    diff := to_integer(eb - ea);
                    e_big := to_integer(eb);
                    m_big := mb; m_small := shift_right(ma, diff);
                    s_res := sb;
                end if;

                if sa = sb then
                    sum := resize(m_big, 28) + resize(m_small, 28);
                else
                    sum := resize(m_big, 28) - resize(m_small, 28);
                end if;

                if sum(27) = '1' then 
                    result(22 downto 0) <= std_logic_vector(sum(26 downto 4));
                    result(30 downto 23) <= std_logic_vector(to_unsigned(e_big + 1, 8));
                elsif sum = 0 then
                    result <= (others => '0');
                else
                    lz := lzc27(sum(26 downto 0)); 
                    if (e_big - lz) <= 0 then 
                        result(22 downto 0) <= std_logic_vector(shift_left(sum(26 downto 0), e_big-1)(25 downto 3));
                        result(30 downto 23) <= (others => '0');
                    else
                        result(22 downto 0) <= std_logic_vector(shift_left(sum(26 downto 0), lz)(25 downto 3));
                        result(30 downto 23) <= std_logic_vector(to_unsigned(e_big - lz, 8));
                    end if;
                end if;
                
                result(31) <= s_res;
                ready <= '1';
            end if;
        end if;
    end process;
end Behavioral;