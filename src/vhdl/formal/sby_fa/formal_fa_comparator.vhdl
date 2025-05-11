library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_linkruncca_pkg.all;

entity formal_fa_comparator is
    generic(
        imwidth: positive := 10;
        imheight: positive := 10;
        x_bit: positive := 8;
        y_bit: positive := 8;
        address_bit: positive := 7;
        data_bit: positive := 32;
        latency: natural := 3;
        rstx: positive := imwidth - latency;
        rsty: positive := imheight - 1;
        compx: positive := imwidth - 1
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        datavalid: in std_logic;
        pix_in: in linkruncca_collect_t;
        DAC: in std_logic;
        DMG: in std_logic;
        CLR: in std_logic;
        dp: in linkruncca_feature_t
    );
end;

architecture formal of formal_fa_comparator is
    component feature_accumulator is
        generic(
            imwidth: positive;
            imheight: positive;
            x_bit: positive;
            y_bit: positive;
            address_bit: positive;
            data_bit: positive;
            latency: natural;
            rstx: positive;
            rsty: positive;
            compx: positive
        );
        port(
            clk: in std_logic;
            rst: in std_logic;
            datavalid: in std_logic;
            DAC: in std_logic;
            DMG: in std_logic;
            CLR: in std_logic;
            dp: in std_logic_vector(data_bit-1 downto 0);
            d: out std_logic_vector(data_bit-1 downto 0)
        );
    end component;
    signal vhdl_d: linkruncca_feature_t;
    signal verilog_d_raw: std_logic_vector(data_bit-1 downto 0);
    signal dp_verilog: std_logic_vector(data_bit-1 downto 0);

    signal vhdl_x_left: unsigned(x_bit-1 downto 0);
    signal verilog_x_left: unsigned(x_bit-1 downto 0);
begin
    vhdl_dut: entity work.vhdl_feature_accumulator
        generic map(
            imwidth => imwidth,
            imheight => imheight,
            x_bit => x_bit,
            y_bit => y_bit,
            address_bit => address_bit,
            latency => latency,
            rstx => rstx,
            rsty => rsty,
            compx => compx
        )
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            pix_in => pix_in,
            DAC => DAC,
            DMG => DMG,
            CLR => CLR,
            dp => dp,
            d => vhdl_d
        );

    process(all)
    begin
        dp_verilog(data_bit-1 downto data_bit-x_bit) <= std_logic_vector(dp.x_left);
        dp_verilog(data_bit-x_bit-1 downto 2*y_bit) <= std_logic_vector(dp.x_right);
        dp_verilog(2*y_bit-1 downto y_bit) <= std_logic_vector(dp.y_top);
        dp_verilog(y_bit-1 downto 0) <= std_logic_vector(dp.y_bottom);
    end process;

    verilog_dut: feature_accumulator
        generic map(
            imwidth => imwidth,
            imheight => imheight,
            x_bit => x_bit,
            y_bit => y_bit,
            address_bit => address_bit,
            data_bit => data_bit,
            latency => latency,
            rstx => rstx,
            rsty => rsty,
            compx => compx
        )
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            DAC => DAC,
            DMG => DMG,
            CLR => CLR,
            dp => dp_verilog,
            d => verilog_d_raw
        );
    
    process(all)
    begin
        vhdl_x_left <= vhdl_d.x_left;
        verilog_x_left <= unsigned(verilog_d_raw(data_bit-1 downto data_bit-x_bit));
    end process;

    -- Formal part =>

    default clock is rising_edge(clk);

    a_rst_0: assume rst = '1';

    f_out_equal_0: assert always {rst = '0'[*1]} |-> vhdl_x_left = verilog_x_left;
    f_out_equal_1: assert always vhdl_x_left = verilog_x_left;
end;
