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
        latency: natural := 3
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        datavalid: in std_logic;
        pix_in: in linkruncca_collect_t;
        DAC: in std_logic;
        DMG: in std_logic;
        CLR: in std_logic;
        dp: in linkruncca_feature_t;
        d: out linkruncca_feature_t
    );
end;

architecture rtl of vhdl_feature_accumulator is
    signal dac_d1: std_logic;
    signal dmg_d1: std_logic;
    signal clr_d1: std_logic;

    signal d_pix: linkruncca_feature_t;
    signal d_pix_d1: linkruncca_feature_t;
    signal d_acc: linkruncca_feature_t;

    -- signal feature_feed: linkruncca_feature_t;
begin
    /*feature_precalc_i: entity work.feature_precalc
        port map(
            clk_in => clk,
            collect_in => pix_in,
            feature_out => feature_feed
        );*/

    input_async_pr: process(all)
        variable pix_data: linkruncca_collect_t;
        variable label_data_pix: linkruncca_feature_t;
    begin
        pix_data := pix_in;
        label_data_pix := linkruncca_feature_collect(pix_data);
        -- label_data_pix := feature_feed;

        d_pix <= linkruncca_feature_empty_val;
        case std_logic_vector'(dmg & dac) is
            when "00" =>
                null;
            when "01" =>
                d_pix <= label_data_pix;
            when "10" =>
                d_pix <= dp;
            when "11" =>
                d_pix <= linkruncca_feature_merge(dp, label_data_pix);
            when others =>
                null;
        end case;
    end process;

    pre_acc_sync_pr: process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                dac_d1 <= dac;
                dmg_d1 <= dmg;
                clr_d1 <= clr;
                d_pix_d1 <= d_pix;
            end if;

            if rst = '1' then
                dac_d1 <= '0';
                dmg_d1 <= '0';
                clr_d1 <= '0';
                d_pix_d1 <= linkruncca_feature_empty_val;
            end if;
        end if;
    end process;

    pre_acc_async_pr: process(all)
    begin
        d <= d_acc;
        case std_logic_vector'(dmg_d1 & dac_d1) is
            when "00" =>
                null;
            when "01" =>
                d <= linkruncca_feature_merge(d_acc, d_pix_d1);
            when "10" =>
                d <= linkruncca_feature_merge(d_acc, d_pix_d1);
            when "11" =>
                d <= linkruncca_feature_merge(d_acc, d_pix_d1);
            when others =>
                null;
        end case;

        if clr_d1 = '1' then
            d <= linkruncca_feature_empty_val;
        end if;

        if rst = '1' then
            d <= linkruncca_feature_empty_val;
        end if;
    end process;

    acc_sync_pr: process(clk, rst)
    begin
        if rising_edge(clk) then
            d_acc <= d;
        end if;

        if rst = '1' then
            d_acc <= linkruncca_feature_empty_val;
        end if;
    end process;
end;
