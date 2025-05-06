/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_feature_accumulator
Date: 2016-04-24

Copyright (C) 2016 J.W. Tang
----------------------------
This file is part of LinkRunCCA.

LinkRunCCA is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

LinkRunCCA is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with LinkRunCCA. If not, see <http://www.gnu.org/licenses/>.

By using LinkRunCCA in any or associated publication,
you agree to cite it as: 
Tang, J. W., et al. "A linked list run-length-based single-pass
connected component analysis for real-time embedded hardware."
Journal of Real-Time Image Processing: 1-19. 2016.
doi:10.1007/s11554-016-0590-2. 

***************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vhdl_feature_accumulator is
    generic(
        imwidth: positive := 512;
        imheight: positive := 512;
        x_bit: positive := 9;
        y_bit: positive := 9;
        address_bit: positive := 8;
        data_bit: positive := 38;
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

architecture rtl of vhdl_feature_accumulator is
    signal x: unsigned(x_bit-1 downto 0);
    signal y: unsigned(y_bit-1 downto 0);

    signal minx: unsigned(x_bit-1 downto 0);
    signal maxx: unsigned(x_bit-1 downto 0);
    signal minx1: unsigned(x_bit-1 downto 0);
    signal maxx1: unsigned(x_bit-1 downto 0);

    signal miny: unsigned(y_bit-1 downto 0);
    signal maxy: unsigned(y_bit-1 downto 0);
    signal miny1: unsigned(y_bit-1 downto 0);
    signal maxy1: unsigned(y_bit-1 downto 0);

    signal d_us: unsigned(data_bit-1 downto 0);
    signal dp_us: unsigned(data_bit-1 downto 0);
begin
    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                if x = compx then
                    x <= to_unsigned(0, x);
                    if y = rsty then
                        y <= to_unsigned(0, y);
                    else
                        y <= y + 1;
                    end if;
                else
                    x <= x + 1;
                end if;
            end if;

        end if;

        if rst = '1' then
            x <= to_unsigned(rstx, x);
            y <= to_unsigned(rsty, y);
        end if;
    end process;

    process(all)
    begin
        d_us <= unsigned(d);
        dp_us <= unsigned(dp);

        minx1 <= x when dac = '1' and (x < d_us(data_bit-1 downto data_bit - x_bit)) else d_us(data_bit - 1 downto data_bit - x_bit);
        maxx1 <= x when dac = '1' and (x > d_us(data_bit - x_bit - 1 downto 2*y_bit)) else d_us(data_bit - x_bit - 1 downto 2*y_bit);
        miny1 <= y when dac = '1' and (y < d_us(2*y_bit - 1 downto y_bit)) else d_us(2*y_bit - 1 downto y_bit);
        maxy1 <= y when dac = '1' and (y > d_us(y_bit-1 downto 0)) else d_us(y_bit-1 downto 0);

        minx <= dp_us(data_bit-1 downto data_bit-x_bit) when dmg = '1' and dp_us(data_bit - 1 downto data_bit - x_bit) < minx1 else minx1;
        maxx <= dp_us(data_bit-x_bit - 1 downto 2*y_bit) when dmg = '1' and dp_us(data_bit - x_bit - 1 downto 2*y_bit) > maxx1 else maxx1;
        miny <= dp_us(2*y_bit - 1 downto y_bit) when dmg = '1' and dp_us(2*y_bit - 1 downto y_bit) < miny1 else miny1;
        maxy <= dp_us(y_bit-1 downto 0) when dmg = '1' and dp_us(y_bit - 1 downto 0) > maxy1 else maxy1;
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                if clr = '1' then
                    d(data_bit - 1 downto data_bit - x_bit) <= (others => '1');
                    d(data_bit - x_bit - 1 downto 2*y_bit) <= (others => '0');
                    d(2*y_bit - 1 downto y_bit) <= (others => '1');
                    d(y_bit-1 downto 0) <= (others => '0');
                else
                    d(data_bit - 1 downto data_bit - x_bit) <= std_logic_vector(minx);
                    d(data_bit - x_bit - 1 downto 2*y_bit) <= std_logic_vector(maxx);
                    d(2*y_bit - 1 downto y_bit) <= std_logic_vector(miny);
                    d(y_bit-1 downto 0) <= std_logic_vector(maxy);
                end if;
            end if;
        end if;

        if rst = '1' then
            d(data_bit - 1 downto data_bit - x_bit) <= (others => '1');
            d(data_bit - x_bit - 1 downto 2*y_bit) <= (others => '0');
            d(2*y_bit - 1 downto y_bit) <= (others => '1');
            d(y_bit-1 downto 0) <= (others => '0');
        end if;
    end process;
end;
