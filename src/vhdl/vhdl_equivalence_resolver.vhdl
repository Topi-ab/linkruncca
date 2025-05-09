/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_equivalence_resolver
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

entity vhdl_equivalence_resolver is
    generic(
        address_bit: positive := 9
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        datavalid: in std_logic;
        A: in std_logic;
        B: in std_logic;
        C: in std_logic;
        D: in std_logic;
        p: in unsigned(address_bit-1 downto 0);
        hp: in unsigned(address_bit-1 downto 0);
        np: in unsigned(address_bit-1 downto 0);
        tp: in unsigned(address_bit-1 downto 0);
        dp: in linkruncca_feature_t;
        fp: in std_logic;
        fn: in std_logic;
        dd: in linkruncca_feature_t;
        h_we: out std_logic;
        t_we: out std_logic;
        n_we: out std_logic;
        d_we: out std_logic;
        h_waddr: out unsigned(address_bit-1 downto 0);
        t_waddr: out unsigned(address_bit-1 downto 0);
        n_waddr: out unsigned(address_bit-1 downto 0);
        d_waddr: out unsigned(address_bit-1 downto 0);
        h_wdata: out unsigned(address_bit-1 downto 0);
        t_wdata: out unsigned(address_bit-1 downto 0);
        n_wdata: out unsigned(address_bit-1 downto 0);
        d_wdata: out linkruncca_feature_t;
        HCN: out std_logic;
        DAC: out std_logic;
        DMG: out std_logic;
        CLR: out std_logic;
        EOC: out std_logic;
        O: out std_logic
    );
end;

architecture rtl of vhdl_equivalence_resolver is
    signal cc: unsigned(address_bit-1 downto 0);
    signal h: unsigned(address_bit-1 downto 0);
    signal f: std_logic;
    signal hbf: std_logic;
    signal ec: std_logic;
    signal ep: std_logic;
begin
    process(all)
    begin
        dmg <= o when not(f = '1' and hp = h) else '0';
        dac <= d;

        ec <= c and not d;
        ep <= a and not b;
        o <= b and d and ((not a) or (not c));
        clr <= ec;
        hcn <= hbf when np = p else '0';
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                if ec = '1' then
                    cc <= cc + 1;
                    f <= '0';
                elsif o = '1' then
                    h <= h_wdata;
                    f <= '1';
                end if;
            end if;
        end if;

        if rst = '1' then
            cc <= (others => '0');
            h <= (others => '0');
            f <= '0';
        end if;
    end process;

    process(all)
    begin
        h_we <= '0';
        h_waddr <= (others => '0');
        h_wdata <= (others => '0');

        t_we <= '0';
        t_waddr <= (others => '0');
        t_wdata <= (others => '0');
        
        n_we <= '0';
        n_waddr <= (others => '0');
        n_wdata <= (others => '0');
        
        d_we <= '0';
        d_waddr <= (others => '0');
        d_wdata <= linkruncca_feature_empty_val;

        eoc <= '0';
        hbf <= '0';

        if ec = '1' then
            n_we <= '1';
            n_waddr <= cc;
            n_wdata <= cc;

            h_we <= '1';
            h_waddr <= cc;
            h_wdata <= cc;

            case f is
                when '0' =>
                    d_we <= '1';
                    d_waddr <= cc;
                    d_wdata <= dd;
                when '1' =>
                    d_we <= '1';
                    d_waddr <= h;
                    d_wdata <= dd;
                when others =>
                    null;
            end case;
        elsif ep = '1' then
            case fp is
                when '0' =>
                    d_we <= '1';
                    d_waddr <= np;
                    d_wdata <= dp;
                    if fn = '1' then
                        eoc <= '1';
                    end if;
                when '1' =>
                    h_we <= '1';
                    h_waddr <= np;
                    h_wdata <= hp;
                    hbf <= '1';
                when others =>
                    null;
            end case;
        elsif o = '1' then
            case std_logic_vector'(f & fp) is
                when "00" =>
                    h_we <= '1';
                    h_waddr <= np;
                    h_wdata <= cc;

                    t_we <= '1';
                    --t_waddr <= h_wdata;
                    t_waddr <= cc;
                    t_wdata <= cc;
                when "01" =>
                    h_we <= '1';
                    h_waddr <= np;
                    h_wdata <= hp;

                    t_we <= '1';
                    --t_waddr <= h_wdata;
                    t_waddr <= hp;
                    t_wdata <= cc;

                    n_we <= '1';
                    n_waddr <= tp;
                    n_wdata <= cc;
                when "10" =>
                    h_we <= '1';
                    h_waddr <= np;
                    h_wdata <= h;

                    t_we <= '1';
                    --t_waddr <= h_wdata;
                    t_waddr <= h;
                    t_wdata <= cc;
                when "11" =>
                    h_we <= '1';
                    h_waddr <= np;
                    h_wdata <= hp;

                    t_we <= '1';
                    --t_waddr <= h_wdata;
                    t_waddr <= hp;
                    t_wdata <= cc;

                    n_we <= '1';
                    n_waddr <= tp;
                    n_wdata <= h;
                when others =>
                    null;
            end case;
        end if;
    end process;
end;
