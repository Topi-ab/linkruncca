/**************************************
Transcoded from original verilog to VHDL-2008.

Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: vhdl_linkruncca
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
use ieee.math_real.all;

use work.vhdl_linkruncca_pkg.all;

entity vhdl_linkruncca is
    generic(
        imwidth: integer := 130;
        imheight: integer := 130
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        datavalid: in std_logic;
        pix_in: in linkruncca_collect_t;
        res_valid_out: out std_logic;
        res_data_out: out linkruncca_feature_t
    );
end;

architecture rtl of vhdl_linkruncca is
    constant latency: integer := 3;

    -- RAM signals
    signal n_waddr: unsigned(mem_add_bits - 1 downto 0);
    signal n_wdata: unsigned(mem_add_bits - 1 downto 0);
    signal n_raddr: unsigned(mem_add_bits - 1 downto 0);
    signal n_rdata: unsigned(mem_add_bits - 1 downto 0);
    signal h_waddr: unsigned(mem_add_bits - 1 downto 0);
    signal h_wdata: unsigned(mem_add_bits - 1 downto 0);
    signal h_raddr: unsigned(mem_add_bits - 1 downto 0);
    signal h_rdata: unsigned(mem_add_bits - 1 downto 0);
    signal t_waddr: unsigned(mem_add_bits - 1 downto 0);
    signal t_wdata: unsigned(mem_add_bits - 1 downto 0); 
    signal t_raddr: unsigned(mem_add_bits - 1 downto 0); 
    signal t_rdata: unsigned(mem_add_bits - 1 downto 0);
    signal d_raddr: unsigned(mem_add_bits - 1 downto 0);
    signal d_waddr: unsigned(mem_add_bits - 1 downto 0);
    signal d_rdata: linkruncca_feature_t;
    signal d_wdata: linkruncca_feature_t;
    signal n_we: std_logic;
    signal h_we: std_logic;
    signal t_we: std_logic;
    signal d_we: std_logic;

    -- Connection signals
    signal A: std_logic;
    signal B: std_logic;
    signal C: std_logic;
    signal D: std_logic;
    signal r1: std_logic;
    signal r2: std_logic;
    signal fp: std_logic;
    signal fn: std_logic;
    signal O: std_logic;
    signal HCN: std_logic;
    signal DAC: std_logic;
    signal DMG: std_logic;
    signal CLR: std_logic;
    signal EOC: std_logic;
    signal p: unsigned(mem_add_bits - 1 downto 0);
    signal hp: unsigned(mem_add_bits - 1 downto 0);
    signal tp: unsigned(mem_add_bits - 1 downto 0);
    signal np: unsigned(mem_add_bits - 1 downto 0);
    signal dd: linkruncca_feature_t;
    signal dp: linkruncca_feature_t;
    signal left: std_logic;
    signal hr1: std_logic;
    signal hf_out: std_logic;

    signal pix_d1: linkruncca_collect_t;
    signal pix_d2: linkruncca_collect_t;
    signal pix_d3: linkruncca_collect_t;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if datavalid = '1' then
                pix_d1 <= pix_in;
                pix_d2 <= pix_d1;
                pix_d3 <= pix_d2;
            end if;
        end if;
    end process;

    -- Table RAMs
    Next_Table: entity work.vhdl_table_ram_add
        generic map(
            data_width => mem_add_bits, 
            address_width => mem_add_bits
        )
        port map(
            clk => clk,
            we => n_we and datavalid,
            write_addr => n_waddr,
            data => std_logic_vector(n_wdata),
            read_addr => n_raddr,
            unsigned(q) => n_rdata
      );

    Head_Table: entity work.vhdl_table_ram_add
        generic map(
            data_width => mem_add_bits,
            address_width => mem_add_bits
        )
        port map(
            clk => clk,
            we => h_we and datavalid,
            write_addr => h_waddr,
            data => std_logic_vector(h_wdata),
            read_addr => h_raddr,
            unsigned(q) => h_rdata
        );

    Tail_Table: entity work.vhdl_table_ram_add
        generic map(
            data_width => mem_add_bits,
            address_width => mem_add_bits
        )
        port map(
            clk => clk,
            we => t_we and datavalid,
            write_addr => t_waddr,
            data => std_logic_vector(t_wdata),
            read_addr => t_raddr,
            unsigned(q) => t_rdata
        );

    Data_Table: entity work.vhdl_table_ram_data
        generic map(
            address_width => mem_add_bits
        )
        port map(
            clk => clk,
            we => d_we and datavalid,
            write_addr => d_waddr,
            data => d_wdata,
            read_addr => d_raddr,
            q => d_rdata
        );

    -- Holes Filler
    HF: entity work.vhdl_holes_filler
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            pix_in_current => pix_in.in_label,
            pix_in_previous => hr1,
            left => left,
            pix_out => hf_out
        );

    RBHF: entity work.vhdl_row_buf
        generic map(
            length => imwidth - 2
        )
        port map(
            clk => clk,
            datavalid => datavalid,
            pix_in => left,
            pix_out1 => hr1
        );

    -- Window and row buffer
    WIN: entity work.vhdl_window
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            pix_in_current => hf_out,
            pix_in_previous => r1,
            A => A,
            B => B,
            C => C,
            D => D
        );

    RB: entity work.vhdl_row_buf
        generic map(
            length => imwidth - 2
        )
        port map(
            clk => clk,
            datavalid => datavalid,
            pix_in => C,
            pix_out1 => r1,
            pix_out2 => r2
        );

    -- Table Reader
    TR: entity work.vhdl_table_reader
        generic map(
            address_bit => mem_add_bits
        )
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            A => A,
            B => B,
            r1 => r1,
            r2 => r2,
            d => dd,
            O => O,
            HCN => HCN,
            d_we => d_we,
            d_waddr => d_waddr,
            h_rdata => h_rdata,
            t_rdata => t_rdata,
            n_rdata => n_rdata,
            d_rdata => d_rdata,
            h_wdata => h_wdata,
            t_wdata => t_wdata,
            h_raddr => h_raddr,
            t_raddr => t_raddr,
            n_raddr => n_raddr,
            d_raddr => d_raddr,
            p => p,
            hp => hp,
            np => np,
            tp => tp,
            dp => dp,
            fp => fp,
            fn => fn
        );

    -- Equivalence Resolver
    ES: entity work.vhdl_equivalence_resolver
        generic map(
            address_bit => mem_add_bits
        )
        port map(
            clk => clk,
            rst => rst,
            datavalid => datavalid,
            A => A,
            B => B,
            C => C,
            D => D,
            p => p,
            hp => hp,
            np => np,
            tp => tp,
            dp => dp,
            fp => fp,
            fn => fn,
            dd => dd,
            h_we => h_we,
            t_we => t_we,
            n_we => n_we,
            d_we => d_we,
            h_waddr => h_waddr,
            t_waddr => t_waddr,
            n_waddr => n_waddr,
            d_waddr => d_waddr,
            h_wdata => h_wdata,
            t_wdata => t_wdata,
            n_wdata => n_wdata,
            d_wdata => d_wdata,
            HCN => HCN,
            DAC => DAC,
            DMG => DMG,
            CLR => CLR,
            EOC => EOC,
            O => O
        );

      -- Feature Accumulator
      FA: entity work.vhdl_feature_accumulator
        generic map(
            imwidth => imwidth,
            imheight => imheight,
            latency => latency
       )
        port map(
            clk => clk, 
            rst => rst, 
            datavalid => datavalid,
            pix_in => pix_d3,
            DAC => DAC, 
            DMG => DMG, 
            CLR => CLR, 
            dp => dp, 
            d => dd
        );

    -- Output register process
    process(clk, rst)
    begin
        if rising_edge(clk) then
            res_valid_out <= '0';

            if datavalid = '1' then
                res_valid_out <= '0';
                if EOC = '1' then
                    res_data_out <= dp;
                    res_valid_out <= '1';
                end if;
            end if;
        end if;

        if rst = '1' then
            res_valid_out <= '0';
        end if;
    end process;
end;
