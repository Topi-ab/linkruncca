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

entity vhdl_window is
    port(
        clk: in std_logic;
        datavalid: in std_logic;
        pix_in_current: in std_logic;
        pix_in_previous: in std_logic;
        a: out std_logic;
        b: out std_logic;
        c: out std_logic;
        d: out std_logic
    );
end;

architecture rtl of vhdl_window is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                a <= b;
                b <= pix_in_previous;
                c <= d;
                d <= pix_in_current;
            end if;
        end if;
    end process;
end;
