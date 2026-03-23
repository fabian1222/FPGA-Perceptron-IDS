library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity perceptron_tb is
end perceptron_tb;

architecture sim of perceptron_tb is
   
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal train_en : std_logic := '0';
    signal x1       : std_logic_vector(31 downto 0) := (others => '0');
    signal x2       : std_logic_vector(31 downto 0) := (others => '0');
    signal bias_in  : std_logic_vector(31 downto 0) := x"3F800000"; -- 1.0f
    signal d_label  : std_logic_vector(31 downto 0) := (others => '0');
    signal alpha    : std_logic_vector(31 downto 0) := x"3DCCCCCD"; -- 0.1f
    
    signal output_y : std_logic_vector(31 downto 0);
    signal done     : std_logic;

    
    signal w1_out   : std_logic_vector(31 downto 0);
    signal w2_out   : std_logic_vector(31 downto 0);
    signal wb_out   : std_logic_vector(31 downto 0);

    constant clk_period : time := 10 ns;

begin
    uut: entity work.perceptron_top
        port map (
            clk      => clk,
            reset    => reset,
            train_en => train_en,
            x1       => x1,
            x2       => x2,
            bias_in  => bias_in,
            d_label  => d_label,
            alpha    => alpha,
            output_y => output_y,
            done     => done,

            w1_out   => w1_out,
            w2_out   => w2_out,
            wb_out   => wb_out
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- TEST 1: Intrare (1.0, 1.0) cu Etichetă (1.0) -> Poarta AND
        x1 <= x"3F800000"; 
        x2 <= x"3F800000";
        d_label <= x"3F800000"; 
        train_en <= '1';
        
        wait for 100 ns;
        train_en <= '0';
        
        -- TEST 2: Intrare (0.0, 1.0) cu Etichetă (0.0)
        x1 <= x"00000000"; 
        x2 <= x"3F800000";
        d_label <= x"00000000";
        train_en <= '1';
        
        wait for 100 ns;
        train_en <= '0';

        wait for 100 ns;
        assert false report "Simulare terminata cu succes" severity failure;
    end process;

end sim;
