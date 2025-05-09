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

use work.vhdl_linkruncca_pkg.all;

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
        dp: in linkruncca_feature_t;
        d: out linkruncca_feature_t
    );
end;

architecture rtl of vhdl_feature_accumulator is
    signal x: unsigned(x_bit-1 downto 0);
    signal y: unsigned(y_bit-1 downto 0);

    signal next_label_data: linkruncca_feature_t;
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
        variable pix_data: linkruncca_collect_t;
        variable label_data_current: linkruncca_feature_t;
        variable label_data_pix: linkruncca_feature_t;
        variable label_data_old: linkruncca_feature_t;
        variable label_data_new: linkruncca_feature_t;
    begin
        pix_data.x := x;
        pix_data.y := y;

        label_data_pix := linkruncca_feature_collect(pix_data);

        label_data_old := dp;

        label_data_current := d;

        label_data_new := label_data_current;

        if dac = '1' then
            label_data_new := linkruncca_feature_merge(label_data_new, label_data_pix);
        end if;

        if dmg = '1' then
            label_data_new := linkruncca_feature_merge(label_data_new, label_data_old);
        end if;

        if clr = '1' then
            label_data_new := linkruncca_feature_empty_val;
        end if;

        if rst = '1' then
            label_data_new := linkruncca_feature_empty_val;
        end if;

        next_label_data <= label_data_new;
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                d <= next_label_data;
            end if;
        end if;
    end process;
end;
