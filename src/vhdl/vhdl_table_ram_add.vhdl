/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_table_ram
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

entity vhdl_table_ram_add is
    generic(
        data_width: positive := 8;
        address_width: positive := 10
    );
    port(
        clk: in std_logic;
        we: in std_logic;
        write_addr: in unsigned(address_width-1 downto 0);
        data: in std_logic_vector(data_width-1 downto 0);
        read_addr: in unsigned(address_width-1 downto 0);
        q: out std_logic_vector(data_width-1 downto 0)
    );
end;

architecture rtl of vhdl_table_ram_add is
    type ram_t is array(0 to 2**address_width-1) of std_logic_vector(data_width-1 downto 0);
    signal ram: ram_t;
    signal read_addr_reg: unsigned(address_width-1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            read_addr_reg <= read_addr;
            if we = '1' then
                ram(to_integer(write_addr)) <= data;
            end if;
        end if;
    end process;

    process(all)
    begin
        q <= ram(to_integer(read_addr_reg));
    end process;
end;
