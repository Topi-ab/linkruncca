library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package vhdl_linkruncca_pkg is
    constant x_size: integer := 200;
    constant y_size: integer := 200;

    constant pix_count: integer := x_size*y_size;

    constant x_bits: integer := integer(ceil(log2(real(x_size))));
    constant y_bits: integer := integer(ceil(log2(real(y_size))));
    constant pix_count_bits: integer := integer(ceil(log2(real(pix_count))));

    constant mem_add_bits: integer := x_bits-1;

    constant box_bits: integer := 2*x_bits + 2*y_bits;

    constant x_sum_bits: integer := x_bits + pix_count_bits;
    constant y_sum_bits: integer := y_bits + pix_count_bits;
    constant x2_sum_bits: integer := 2*x_bits + pix_count_bits;
    constant y2_sum_bits: integer := 2*y_bits + pix_count_bits;
    constant xy_sum_bits: integer := x_bits+y_bits + pix_count_bits;

    -- This structure holds data from single pixel, which needs to be collected to feature.
    type linkruncca_collect_t is record
        in_label: std_logic; -- '1' is object to be detected. '0' is background.
        x: unsigned(x_bits-1 downto 0);
        y: unsigned(y_bits-1 downto 0);
        has_red: std_logic;
        has_green: std_logic;
        has_blue: std_logic;
    end record;

    -- This structure holds features for single label.
    type linkruncca_feature_t is record
        x_left: unsigned(x_bits-1 downto 0);
        x_right: unsigned(x_bits-1 downto 0);
        y_top: unsigned(y_bits-1 downto 0);
        y_bottom: unsigned(y_bits-1 downto 0);
        pix_count: unsigned(pix_count_bits-1 downto 0);
        x_sum: unsigned(x_sum_bits-1 downto 0);
        y_sum: unsigned(y_sum_bits-1 downto 0);
        x2_sum: unsigned(x2_sum_bits-1 downto 0);
        y2_sum: unsigned(y2_sum_bits-1 downto 0);
        xy_sum: unsigned(xy_sum_bits-1 downto 0);
        -- 
    end record;

    function linkruncca_feature_empty_val return linkruncca_feature_t;
    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t;
    function linkruncca_feature_merge(a: linkruncca_feature_t; b: linkruncca_feature_t) return linkruncca_feature_t;
    function min(a: unsigned; b: unsigned) return unsigned;
    function max(a: unsigned; b: unsigned) return unsigned;
end;

package body vhdl_linkruncca_pkg is
    function linkruncca_feature_empty_val return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
    begin
        r.x_left := (others => '1');
        r.x_right := (others => '0');
        r.y_top := (others => '1');
        r.y_bottom := (others => '0');
        r.pix_count := (others => '0');
        r.x_sum := (others => '0');
        r.y_sum := (others => '0');
        r.x2_sum := (others => '0');
        r.y2_sum := (others => '0');
        r.xy_sum := (others => '0');

        return r;
    end;

    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
    begin
        r.x_left := a.x;
        r.x_right := a.x;
        r.y_top := a.y;
        r.y_bottom := a.y;
        r.pix_count := to_unsigned(1, r.pix_count);
        r.x_sum := resize(a.x, r.x_sum);
        r.y_sum := resize(a.y, r.y_sum);
        r.x2_sum := resize(a.x*a.x, r.x2_sum);
        r.y2_sum := resize(a.y*a.y, r.y2_sum);
        r.xy_sum := resize(a.x*a.y, r.xy_sum);
        return r;
    end;

    function linkruncca_feature_merge(
            a: linkruncca_feature_t;
            b: linkruncca_feature_t
        ) return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
    begin
        r := a;

        r.x_left := min(r.x_left, b.x_left);
        r.x_right := max(r.x_right, b.x_right);
        r.y_top := min(r.y_top, b.y_top);
        r.y_bottom := max(r.y_bottom, b.y_bottom);
        r.pix_count := r.pix_count + b.pix_count;
        r.x_sum := r.x_sum + b.x_sum;
        r.y_sum := r.y_sum + b.y_sum;
        r.x2_sum := r.x2_sum + b.x2_sum;
        r.y2_sum := r.y2_sum + b.y2_sum;
        r.xy_sum := r.xy_sum + b.xy_sum;

        return r;
    end;

    function min(a: unsigned; b: unsigned) return unsigned is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end;

    function max(a: unsigned; b: unsigned) return unsigned is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end;
end;
