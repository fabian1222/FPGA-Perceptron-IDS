library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul is
    Port (
        a      : in  STD_LOGIC_VECTOR(31 downto 0);
        b      : in  STD_LOGIC_VECTOR(31 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0)
    );
end mul;

architecture Behavioral of mul is
    constant bias : integer := 127;
    constant EXP_MAX : unsigned(7 downto 0) := x"FF";

    function qnan return std_logic_vector is
        variable r : std_logic_vector(31 downto 0);
    begin
        r(31) := '0';
        r(30 downto 23) := (others => '1');
        r(22 downto 0) := "10000000000000000000000";
        return r;
    end function;

    function or_reduce(u : unsigned) return std_logic is
        variable v : std_logic := '0';
    begin
        for i in u'range loop
            v := v or std_logic(u(i));
        end loop;
        return v;
    end function;

begin
    process(a, b)
        variable sa, sb : std_logic;
        variable ea, eb : unsigned(7 downto 0);
        variable fa, fb : unsigned(22 downto 0);

        variable zero_a, zero_b : boolean;
        variable inf_a, inf_b   : boolean;
        variable nan_a, nan_b   : boolean;

        variable ea_eff, eb_eff : integer;

        variable sign_r : std_logic;
        variable exp_res_i : integer;

        variable ma24, mb24 : unsigned(23 downto 0);
        variable prod48 : unsigned(47 downto 0);

        -- mant_norm: 27b cu GRS: [26]=hidden, [25:3]=frac, [2]=G, [1]=R, [0]=S
        variable mant_norm : unsigned(26 downto 0);

        variable guard_b, round_b, sticky_b : std_logic;
        variable lsb_kept : std_logic;
        variable inc : std_logic;

        variable frac_out : unsigned(22 downto 0);
        variable exp_out  : unsigned(7 downto 0);

        variable res_v : std_logic_vector(31 downto 0);
    begin
        sa := a(31); sb := b(31);
        ea := unsigned(a(30 downto 23));
        eb := unsigned(b(30 downto 23));
        fa := unsigned(a(22 downto 0));
        fb := unsigned(b(22 downto 0));

        zero_a := (ea = 0) and (fa = 0);
        zero_b := (eb = 0) and (fb = 0);

        inf_a := (ea = EXP_MAX) and (fa = 0);
        inf_b := (eb = EXP_MAX) and (fb = 0);

        nan_a := (ea = EXP_MAX) and (fa /= 0);
        nan_b := (eb = EXP_MAX) and (fb /= 0);

        sign_r := sa xor sb;
        res_v := (others => '0');

        -- ==== Cazuri speciale ====
        if nan_a or nan_b or ((inf_a or inf_b) and (zero_a or zero_b)) then
            res_v := qnan;

        elsif inf_a or inf_b then
            -- ±Inf
            res_v(31) := sign_r;
            res_v(30 downto 23) := (others => '1');
            res_v(22 downto 0) := (others => '0');

        elsif zero_a or zero_b then
            
            res_v := (others => '0');
            res_v(31) := sign_r;

        else
            
            if ea = 0 then ea_eff := 1; else ea_eff := to_integer(ea); end if;
            if eb = 0 then eb_eff := 1; else eb_eff := to_integer(eb); end if;

            
            if ea = 0 then
                ma24 := ("0" & fa);
            else
                ma24 := ("1" & fa);
            end if;

            if eb = 0 then
                mb24 := ("0" & fb);
            else
                mb24 := ("1" & fb);
            end if;

            prod48 := ma24 * mb24;

            exp_res_i := ea_eff + eb_eff - bias;

           
            if prod48(47) = '1' then
                
                mant_norm(26 downto 3) := prod48(47 downto 24);
                mant_norm(2) := prod48(23);                 
                mant_norm(1) := prod48(22);                 
                mant_norm(0) := or_reduce(prod48(21 downto 0)); 
                exp_res_i := exp_res_i + 1;
            else
               
                mant_norm(26 downto 3) := prod48(46 downto 23);
                mant_norm(2) := prod48(22);
                mant_norm(1) := prod48(21);
                mant_norm(0) := or_reduce(prod48(20 downto 0));
            end if;

           
            guard_b  := mant_norm(2);
            round_b  := mant_norm(1);
            sticky_b := mant_norm(0);
            lsb_kept := mant_norm(3);

            inc := '0';
            if guard_b = '1' then
                if (round_b = '1') or (sticky_b = '1') or (lsb_kept = '1') then
                    inc := '1';
                end if;
            end if;

            if inc = '1' then
                mant_norm := mant_norm + to_unsigned(8, mant_norm'length); 
                
                if mant_norm(26) = '0' then
                  
                    mant_norm := shift_right(mant_norm, 1);
                    exp_res_i := exp_res_i + 1;
                end if;
            end if;

            
            if exp_res_i >= 255 then
                
                res_v(31) := sign_r;
                res_v(30 downto 23) := (others => '1');
                res_v(22 downto 0) := (others => '0');
            elsif exp_res_i <= 0 then
               
                res_v := (others => '0');
                res_v(31) := sign_r; 
            else
                exp_out  := to_unsigned(exp_res_i, 8);
                frac_out := mant_norm(25 downto 3); 
                res_v(31) := sign_r;
                res_v(30 downto 23) := std_logic_vector(exp_out);
                res_v(22 downto 0)  := std_logic_vector(frac_out);
            end if;
        end if;

        result <= res_v;
    end process;

end Behavioral;