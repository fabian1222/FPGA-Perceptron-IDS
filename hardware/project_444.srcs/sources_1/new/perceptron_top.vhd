library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity perceptron_top is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        train_en : in  STD_LOGIC;
        x1       : in  STD_LOGIC_VECTOR(31 downto 0);
        x2       : in  STD_LOGIC_VECTOR(31 downto 0);
        bias_in  : in  STD_LOGIC_VECTOR(31 downto 0);
        d_label  : in  STD_LOGIC_VECTOR(31 downto 0);
        alpha    : in  STD_LOGIC_VECTOR(31 downto 0);
        output_y : out STD_LOGIC_VECTOR(31 downto 0);
        done     : out STD_LOGIC;

        w1_out   : out STD_LOGIC_VECTOR(31 downto 0);
        w2_out   : out STD_LOGIC_VECTOR(31 downto 0);
        wb_out   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end perceptron_top;

architecture Behavioral of perceptron_top is
    signal w1, w2, w_bias : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal w1_next, w2_next, wb_next : STD_LOGIC_VECTOR(31 downto 0);
    
    signal prod1, prod2, prod_b : STD_LOGIC_VECTOR(31 downto 0);
    signal sum_inter, sum_final : STD_LOGIC_VECTOR(31 downto 0);
    signal error_val, delta_common : STD_LOGIC_VECTOR(31 downto 0);
    signal dw1, dw2, dwb : STD_LOGIC_VECTOR(31 downto 0);
    signal y_int : STD_LOGIC_VECTOR(31 downto 0);
    
    signal ready_sum, ready_w1, ready_w2, ready_wb : STD_LOGIC;

begin
    w1_out <= w1;
    w2_out <= w2;
    wb_out <= w_bias;

    M1: entity work.mul port map(a => x1, b => w1, result => prod1);
    M2: entity work.mul port map(a => x2, b => w2, result => prod2);
    MB: entity work.mul port map(a => bias_in, b => w_bias, result => prod_b);

    A1: entity work.adunare_fast port map(clk => clk, reset => reset, a => prod1, b => prod2, result => sum_inter, ready => open);
    A2: entity work.adunare_fast port map(clk => clk, reset => reset, a => sum_inter, b => prod_b, result => sum_final, ready => ready_sum);

    y_int <= x"3F800000" when (sum_final(31) = '0' and sum_final /= x"00000000") else x"00000000";
    output_y <= y_int;

    S1: entity work.scadere port map(clk => clk, reset => reset, a => d_label, b => y_int, result => error_val, ready => open);
    
    MD: entity work.mul port map(a => alpha, b => error_val, result => delta_common);
    
    MW1: entity work.mul port map(a => delta_common, b => x1, result => dw1);
    MW2: entity work.mul port map(a => delta_common, b => x2, result => dw2);
    MWB: entity work.mul port map(a => delta_common, b => bias_in, result => dwb);

    UW1: entity work.adunare_fast port map(clk => clk, reset => reset, a => w1, b => dw1, result => w1_next, ready => ready_w1);
    UW2: entity work.adunare_fast port map(clk => clk, reset => reset, a => w2, b => dw2, result => w2_next, ready => ready_w2);
    UWB: entity work.adunare_fast port map(clk => clk, reset => reset, a => w_bias, b => dwb, result => wb_next, ready => ready_wb);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                w1 <= (others => '0');
                w2 <= (others => '0');
                w_bias <= (others => '0');
                done <= '0';
            else
                if train_en = '1' and ready_w1 = '1' then
                    w1 <= w1_next;
                    w2 <= w2_next;
                    w_bias <= wb_next;
                    done <= '1';
                else
                    done <= ready_sum; 
                end if;
            end if;
        end if;
    end process;

end Behavioral;
