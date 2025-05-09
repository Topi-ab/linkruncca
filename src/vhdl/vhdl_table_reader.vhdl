/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_table_reader
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

entity vhdl_table_reader is
    generic(
        address_bit: positive := 9
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        datavalid: in std_logic;
        A: in std_logic;
        B: in std_logic;
        r1: in std_logic;
        r2: in std_logic;
        O: in std_logic;
        HCN: in std_logic;
        d_we: in std_logic;
        d_waddr: in unsigned(address_bit-1 downto 0);
        h_rdata: in unsigned(address_bit-1 downto 0);
        t_rdata: in unsigned(address_bit-1 downto 0);
        n_rdata: in unsigned(address_bit-1 downto 0);
        h_wdata: in unsigned(address_bit-1 downto 0);
        t_wdata: in unsigned(address_bit-1 downto 0);
        d: in linkruncca_feature_t;
        d_rdata: in linkruncca_feature_t;
        n_raddr: out unsigned(address_bit-1 downto 0);
        h_raddr: out unsigned(address_bit-1 downto 0);
        t_raddr: out unsigned(address_bit-1 downto 0);
        d_raddr: out unsigned(address_bit-1 downto 0);
        p: out unsigned(address_bit-1 downto 0);
        hp: out unsigned(address_bit-1 downto 0);
        np: out unsigned(address_bit-1 downto 0);
        tp: out unsigned(address_bit-1 downto 0);
        dp: out linkruncca_feature_t;
        fp: out std_logic;
        fn: out std_logic
    );
end;

architecture rtl of vhdl_table_reader is
    signal rtp: unsigned(address_bit-1 downto 0);
    signal rdp: linkruncca_feature_t;

    signal pc: unsigned(address_bit-1 downto 0);

    signal dcn: std_logic;
begin
    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                p <= pc;
                if r1 = '1' and r2 = '0' then
                    pc <= pc + 1;
                end if;
            end if;
        end if;

        if rst = '1' then
            pc <= (others => '0');
            p <= (others => '0');
        end if;
    end process;

    process(all)
    begin
        n_raddr <= pc;
        h_raddr <= pc;

        t_raddr <= h_wdata when hcn = '1' else h_rdata;
        d_raddr <= h_wdata when hcn = '1' else h_rdata;
    end process;

    process(all)
    begin
        dcn <= '1' when d_we = '1' and d_waddr = hp else '0';
    end process;

    process(all)
    begin
        tp <= t_rdata when a = '0' and b = '1' else rtp;
        dp <= d_rdata when a = '0' and b = '1' else rdp;
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                rtp <= tp;
                rdp <= dp;
                if dcn = '1' then
                    rdp <= d;
                end if;
                if b = '0' and r1 = '1' then
                    hp <= t_raddr;
                    fp <= '0' when t_raddr = p else '1';
                    np <= n_rdata;
                    fn <= '1' when n_rdata = p else '0';
                elsif o = '1' then
                    rtp <= t_wdata;
                    fp <= '1';
                    hp <= h_wdata;
                end if;
            end if;
        end if;

        if rst = '1' then
            np <= (others => '0');
            hp <= (others => '0');
            fp <= '0';
            fn <= '0';
            rtp <= (others => '0');
            rdp <= linkruncca_feature_empty_val;
        end if;
    end process;
end;
