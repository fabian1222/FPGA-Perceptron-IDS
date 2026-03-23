library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity perceptron_axi_slave_lite_v1_0_S00_AXI is
  generic (
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 6
  );
  port (
    -- Global Clock Signal
    S_AXI_ACLK    : in  std_logic;
    -- Global Reset Signal. Active LOW
    S_AXI_ARESETN : in  std_logic;

    -- Write address channel
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;

    -- Write data channel
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;

    -- Write response channel
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;

    -- Read address channel
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;

    -- Read data channel
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic
  );
end perceptron_axi_slave_lite_v1_0_S00_AXI;

architecture arch_imp of perceptron_axi_slave_lite_v1_0_S00_AXI is

  -- AXI4LITE internal signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- Addressing constants for 32-bit regs
  constant ADDR_LSB          : integer := (C_S_AXI_DATA_WIDTH/32) + 1; -- =2 for 32-bit
  constant OPT_MEM_ADDR_BITS : integer := 3; -- 4-bit decode (ADDR_LSB..ADDR_LSB+3) => up to 16 regs

  -- 10 slave regs: 0..9
  signal slv_reg0 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg1 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg2 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg3 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg4 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg5 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg6 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- y (RO)
  signal slv_reg7 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- w1 (RO)
  signal slv_reg8 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- w2 (RO)
  signal slv_reg9 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- wb (RO)

  signal byte_index : integer;

  -- 4-bit register select
  signal mem_logic : std_logic_vector(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

  -- Simple state machines
  constant Idle  : std_logic_vector(1 downto 0) := "00";
  constant Raddr : std_logic_vector(1 downto 0) := "10";
  constant Rdata : std_logic_vector(1 downto 0) := "11";
  constant Waddr : std_logic_vector(1 downto 0) := "10";
  constant Wdata : std_logic_vector(1 downto 0) := "11";

  signal state_read  : std_logic_vector(1 downto 0);
  signal state_write : std_logic_vector(1 downto 0);

  --------------------------------------------------------------------
  -- USER signals (perceptron)
  --------------------------------------------------------------------
  signal p_reset    : std_logic;
  signal p_train_en : std_logic;

  signal p_x1      : std_logic_vector(31 downto 0);
  signal p_x2      : std_logic_vector(31 downto 0);
  signal p_bias_in : std_logic_vector(31 downto 0);
  signal p_d_label : std_logic_vector(31 downto 0);
  signal p_alpha   : std_logic_vector(31 downto 0);

  signal p_y    : std_logic_vector(31 downto 0);
  signal p_done : std_logic;

  signal p_w1 : std_logic_vector(31 downto 0);
  signal p_w2 : std_logic_vector(31 downto 0);
  signal p_wb : std_logic_vector(31 downto 0);

  -- reg0 la citire = slv_reg0 cu bit2 suprascris cu done
  signal reg0_read : std_logic_vector(31 downto 0);

begin

  -- AXI outputs
  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP   <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RRESP   <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;

  -- 4-bit decode for writes
  mem_logic <= S_AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) when (S_AXI_AWVALID = '1')
               else axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

  --------------------------------------------------------------------
  -- Write state machine
  --------------------------------------------------------------------
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
        axi_wready  <= '0';
        axi_bvalid  <= '0';
        axi_bresp   <= (others => '0');
        state_write <= Idle;
      else
        case state_write is
          when Idle =>
            axi_awready <= '1';
            axi_wready  <= '1';
            state_write <= Waddr;

          when Waddr =>
            if (S_AXI_AWVALID = '1' and axi_awready = '1') then
              axi_awaddr <= S_AXI_AWADDR;

              if (S_AXI_WVALID = '1') then
                axi_awready <= '1';
                state_write <= Waddr;
                axi_bvalid  <= '1';
              else
                axi_awready <= '0';
                state_write <= Wdata;

                if (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                  axi_bvalid <= '0';
                end if;
              end if;
            else
              if (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          when Wdata =>
            if (S_AXI_WVALID = '1') then
              state_write <= Waddr;
              axi_bvalid  <= '1';
              axi_awready <= '1';
            else
              if (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          when others =>
            axi_awready <= '0';
            axi_wready  <= '0';
            axi_bvalid  <= '0';
        end case;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Register write logic
  -- IMPORTANT: CPU writes ONLY regs 0..5
  -- regs 6..9 are read-only (written by perceptron only)
  --------------------------------------------------------------------
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        slv_reg0 <= (others => '0');
        slv_reg1 <= (others => '0');
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
        slv_reg4 <= (others => '0');
        slv_reg5 <= (others => '0');
      else
        if (S_AXI_WVALID = '1') then
          case mem_logic is
            when b"0000" =>  -- reg0 control
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when b"0001" =>  -- reg1 x1
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when b"0010" =>  -- reg2 x2
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when b"0011" =>  -- reg3 bias
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when b"0100" =>  -- reg4 d_label
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when b"0101" =>  -- reg5 alpha
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;

            when others =>
              null;
          end case;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Read state machine
  --------------------------------------------------------------------
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_rvalid  <= '0';
        axi_rresp   <= (others => '0');
        state_read  <= Idle;
      else
        case state_read is
          when Idle =>
            axi_arready <= '1';
            state_read  <= Raddr;

          when Raddr =>
            if (S_AXI_ARVALID = '1' and axi_arready = '1') then
              state_read  <= Rdata;
              axi_rvalid  <= '1';
              axi_arready <= '0';
              axi_araddr  <= S_AXI_ARADDR;
            end if;

          when Rdata =>
            if (axi_rvalid = '1' and S_AXI_RREADY = '1') then
              axi_rvalid  <= '0';
              axi_arready <= '1';
              state_read  <= Raddr;
            end if;

          when others =>
            axi_arready <= '0';
            axi_rvalid  <= '0';
        end case;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- USER LOGIC: perceptron connections
  --------------------------------------------------------------------
  p_train_en <= slv_reg0(0);
  p_reset    <= (not S_AXI_ARESETN) or slv_reg0(1);

  p_x1      <= slv_reg1;
  p_x2      <= slv_reg2;
  p_bias_in <= slv_reg3;
  p_d_label <= slv_reg4;
  p_alpha   <= slv_reg5;

  U_PERCEPTRON: entity work.perceptron_top
    port map (
      clk      => S_AXI_ACLK,
      reset    => p_reset,
      train_en => p_train_en,
      x1       => p_x1,
      x2       => p_x2,
      bias_in  => p_bias_in,
      d_label  => p_d_label,
      alpha    => p_alpha,
      output_y => p_y,
      done     => p_done,
      w1_out   => p_w1,
      w2_out   => p_w2,
      wb_out   => p_wb
    );

  -- regs 6..9 are written ONLY here (read-only for CPU)
  process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        slv_reg6 <= (others => '0'); -- y
        slv_reg7 <= (others => '0'); -- w1
        slv_reg8 <= (others => '0'); -- w2
        slv_reg9 <= (others => '0'); -- wb
      else
        slv_reg6 <= p_y;
        slv_reg7 <= p_w1;
        slv_reg8 <= p_w2;
        slv_reg9 <= p_wb;
      end if;
    end if;
  end process;

  -- reg0 for readback: same as slv_reg0 but bit2 shows done (no multiple driver!)
  reg0_read <= slv_reg0(31 downto 3) & p_done & slv_reg0(1 downto 0);

  --------------------------------------------------------------------
  -- Read mux: include reg0_read and regs 1..9
  --------------------------------------------------------------------
  with axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) select
    S_AXI_RDATA <=
      reg0_read when b"0000",
      slv_reg1  when b"0001",
      slv_reg2  when b"0010",
      slv_reg3  when b"0011",
      slv_reg4  when b"0100",
      slv_reg5  when b"0101",
      slv_reg6  when b"0110",
      slv_reg7  when b"0111",
      slv_reg8  when b"1000",
      slv_reg9  when b"1001",
      (others => '0') when others;

end arch_imp;
