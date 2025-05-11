library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_linkruncca_pkg.all;

entity eqy_feature_accumulator_adapter is
        generic(
            imwidth: positive;
            imheight: positive;
            x_bit: positive;
            y_bit: positive;
            address_bit: positive;
            data_bit: positive;
            latency: natural := 3;
            rstx: positive := imwidth - latency;
            rsty: positive := imheight - 1;
            compx: positive := imwidth - 1
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
end;

architecture eqy of eqy_feature_accumulator_adapter is
    signal pix_vhdl: linkruncca_collect_t;
    signal dp_vhdl: linkruncca_feature_t;
    signal d_vhdl: linkruncca_feature_t;
begin
    process(all)
    begin
        pix_vhdl <= (x => (others => '0'), y => (others => '0'), others => '0');

        dp_vhdl.has_red <= '0';
        dp_vhdl.has_green <= '0';
        dp_vhdl.has_blue <= '0';
        dp_vhdl.x_left <= unsigned(dp(data_bit-1 downto data_bit-x_bit));
        dp_vhdl.x_right <= unsigned(dp(data_bit-x_bit-1 downto 2*y_bit));
        dp_vhdl.y_top <= unsigned(dp(2*y_bit-1 downto y_bit));
        dp_vhdl.y_bottom <= unsigned(dp(y_bit-1 downto 0));
    end process;

    dut: entity work.vhdl_feature_accumulator
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
            pix_in => pix_vhdl,
            DAC => DAC,
            DMG => DMG,
            CLR => CLR,
            dp => dp_vhdl,
            d => d_vhdl
        );
    
    process(all)
    begin
        d(data_bit-1 downto data_bit-x_bit) <= std_logic_vector(d_vhdl.x_left);
        d(data_bit-x_bit-1 downto 2*y_bit) <= std_logic_vector(d_vhdl.x_right);
        d(2*y_bit-1 downto y_bit) <= std_logic_vector(d_vhdl.y_top);
        d(y_bit-1 downto 0) <= std_logic_vector(d_vhdl.y_bottom);
    end process;
end;
