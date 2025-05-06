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

entity vhdl_linkruncca is
    generic(
        imwidth: integer := 512;
        imheight: integer := 512;
        x_bit: integer := integer(ceil(log2(real(imwidth))));
        y_bit: integer := integer(ceil(log2(real(imheight))));
        address_bit: integer := x_bit - 1;
        data_bit: integer := 2 * (x_bit + y_bit);
        latency: integer := 3
    );
    port(
      clk: in std_logic;
      rst: in std_logic;
      datavalid: in std_logic;
      pix_in: in std_logic;
      datavalid_out: out std_logic;
      box_out: out std_logic_vector(data_bit - 1 downto 0)
    );
end;

architecture rtl of vhdl_linkruncca is

    -- RAM signals
    signal n_waddr: unsigned(address_bit - 1 downto 0);
    signal n_wdata: unsigned(address_bit - 1 downto 0);
    signal n_raddr: unsigned(address_bit - 1 downto 0);
    signal n_rdata: unsigned(address_bit - 1 downto 0);
    signal h_waddr: unsigned(address_bit - 1 downto 0);
    signal h_wdata: unsigned(address_bit - 1 downto 0);
    signal h_raddr: unsigned(address_bit - 1 downto 0);
    signal h_rdata: unsigned(address_bit - 1 downto 0);
    signal t_waddr: unsigned(address_bit - 1 downto 0);
    signal t_wdata: unsigned(address_bit - 1 downto 0); 
    signal t_raddr: unsigned(address_bit - 1 downto 0); 
    signal t_rdata: unsigned(address_bit - 1 downto 0);
    signal d_raddr: unsigned(address_bit - 1 downto 0);
    signal d_waddr: unsigned(address_bit - 1 downto 0);
    signal d_rdata: std_logic_vector(data_bit - 1 downto 0); 
    SIGNAL d_wdata: std_logic_vector(data_bit - 1 downto 0);
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
    signal p: unsigned(address_bit - 1 downto 0);
    signal hp: unsigned(address_bit - 1 downto 0);
    signal tp: unsigned(address_bit - 1 downto 0);
    signal np: unsigned(address_bit - 1 downto 0);
    signal dd: std_logic_vector(data_bit - 1 downto 0);
    signal dp: std_logic_vector(data_bit - 1 downto 0);
    signal left: std_logic;
    signal hr1: std_logic;
    signal hf_out: std_logic;

begin

    -- Table RAMs
    Next_Table: entity work.vhdl_table_ram
        generic map(
            data_width => address_bit, 
            address_width => address_bit
        )
        port map(
            clk => clk,
            we => n_we and datavalid,
            write_addr => n_waddr,
            data => std_logic_vector(n_wdata),
            read_addr => n_raddr,
            unsigned(q) => n_rdata
      );

    Head_Table: entity work.vhdl_table_ram
        generic map(
            data_width => address_bit,
            address_width => address_bit
        )
        port map(
            clk => clk,
            we => h_we and datavalid,
            write_addr => h_waddr,
            data => std_logic_vector(h_wdata),
            read_addr => h_raddr,
            unsigned(q) => h_rdata
        );

    Tail_Table: entity work.vhdl_table_ram
        generic map(
            data_width => address_bit,
            address_width => address_bit
        )
        port map(
            clk => clk,
            we => t_we and datavalid,
            write_addr => t_waddr,
            data => std_logic_vector(t_wdata),
            read_addr => t_raddr,
            unsigned(q) => t_rdata
        );

    Data_Table: entity work.vhdl_table_ram
        generic map(
            data_width => data_bit,
            address_width => address_bit
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
            datavalid => datavalid,
            pix_in_current => pix_in,
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
            address_bit => address_bit,
            data_bit => data_bit
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
            address_bit => address_bit,
            data_bit => data_bit
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
            x_bit => x_bit,
            y_bit => y_bit,
            address_bit => address_bit,
            data_bit => data_bit,
            latency => latency
       )
        port map(
            clk => clk, 
            rst => rst, 
            datavalid => datavalid,
            DAC => DAC, 
            DMG => DMG, 
            CLR => CLR, 
            dp => dp, 
            d => dd
        );

    -- Output register process
    process(clk, rst)
    begin
        if rst = '1' then
            datavalid_out <= '0';
        elsif rising_edge(clk) then
            if datavalid = '1' then
                datavalid_out <= '0';
                box_out <= dp;
                if EOC = '1' then
                   datavalid_out <= '1';
                end if;
            end if;
        end if;
    end process;
end;
