/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_window
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

use work.vhdl_linkruncca_util_pkg.all;

entity vhdl_window is
    generic(
        gen_x_size: positive
    );
    port(
        clk_in: in std_logic;
        rst_in: in std_logic;
        pix_valid_in: in std_logic;
        pix_current_in: in std_logic;
        pix_current_orig_in: in std_logic;
        pix_previous_in: in std_logic;
        a_out: out std_logic;
        b_out: out std_logic;
        c_out: out std_logic;
        d_out: out std_logic;
        neighbour_out: out pixel_neighbour_t;
        r1_out: out std_logic;
        r2_out: out std_logic
    );
end;

architecture rtl of vhdl_window is
    constant buff_len: integer := gen_x_size - 1;

    type pix_t is record
        pix: std_logic;
        pix_orig: std_logic;
    end record;

    type pix_buff_a is array(0 to buff_len-1) of pix_t;
    signal pix_buff: pix_buff_a;

    signal pix_current: pix_t;
    signal pix_prev: pix_t;
begin
    process(all)
    begin
        pix_current.pix <= pix_current_in;
        pix_current.pix_orig <= pix_current_orig_in;

        pix_prev <= pix_buff(buff_len-1);

        r1_out <= neighbour_out.e;
        r2_out <= pix_prev.pix;
    end process;

    process(clk_in)
    begin
        if rising_edge(clk_in) then
            if pix_valid_in = '1' then
                pix_buff(1 to buff_len-1) <= pix_buff(0 to buff_len-2);
                pix_buff(0) <= pix_current;

                a_out <= b_out;
                b_out <= pix_previous_in;
                c_out <= d_out;
                d_out <= pix_current_in;

                neighbour_out.a <= neighbour_out.b;
                neighbour_out.b <= neighbour_out.e;
                neighbour_out.e <= pix_prev.pix;
                neighbour_out.c <= neighbour_out.d;
                neighbour_out.d <= pix_current_in;

                neighbour_out.a_orig <= neighbour_out.b_orig;
                neighbour_out.b_orig <= neighbour_out.e_orig;
                neighbour_out.e_orig <= pix_prev.pix_orig;
                neighbour_out.c_orig <= neighbour_out.d_orig;
                neighbour_out.d_orig <= pix_current_orig_in;
            end if;

            if rst_in = '1' then
                a_out <= '0';
                b_out <= '0';
                c_out <= '0';
                d_out <= '0';
            end if;
        end if;
    end process;
end;
