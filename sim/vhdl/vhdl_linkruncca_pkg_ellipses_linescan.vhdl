library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.vhdl_linkruncca_util_pkg.all;

package vhdl_linkruncca_pkg is
    -- USER PARAMETERS =>

    constant x_size: integer := 200;
    constant y_bits: integer := 8;
    
    -- <= USER PARAMETERS.

    constant x_bits: integer := max2bits(x_size-1);

    constant x_max: integer := x_size - 1;
    constant y_low_bits: integer := y_bits - 1;
    constant y_size: integer := 2**y_bits;
    constant y_max: integer := y_size - 1;
    constant y_low_size: integer := 2**y_low_bits;
    constant y_low_max: integer := y_low_size - 1;
    constant n_seg_sum_bits: integer := max2bits(fit(x_size) * fit(y_low_size));

    constant mem_add_bits: integer := x_bits-1;

    constant x2_sum_bits: integer := max2bits(unsigned'(sum_x2(0, x_max))*fit(y_size));
    constant ylow2_sum_bits: integer := max2bits(unsigned'(sum_x2(0, y_low_max)) * fit(x_size));
    constant xylow_sum_bits: integer := max2bits(unsigned'(sum_xy(0, x_max, 0, y_low_max)));
    constant x_seg_sum_bits: integer := max2bits(unsigned'(sum_x(0, x_max))* fit(y_low_size));
    constant ylow_seg_sum_bits: integer := max2bits(unsigned'(sum_x(0, y_low_max)) * fit(x_size));

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
        y_top_seg0: unsigned(y_low_bits-1 downto 0);
        y_top_seg1: unsigned(y_low_bits-1 downto 0);
        y_bottom_seg0: unsigned(y_low_bits-1 downto 0);
        y_bottom_seg1: unsigned(y_low_bits-1 downto 0);
        x2_sum: unsigned(x2_sum_bits-1 downto 0);
        ylow2_sum: unsigned(ylow2_sum_bits-1 downto 0);
        xylow_sum: unsigned(xylow_sum_bits-1 downto 0);
        x_seg0_sum: unsigned(x_seg_sum_bits-1 downto 0);
        x_seg1_sum: unsigned(x_seg_sum_bits-1 downto 0);
        ylow_seg0_sum: unsigned(ylow_seg_sum_bits-1 downto 0);
        ylow_seg1_sum: unsigned(ylow_seg_sum_bits-1 downto 0);
        n_seg0_sum: unsigned(n_seg_sum_bits-1 downto 0);
        n_seg1_sum: unsigned(n_seg_sum_bits-1 downto 0);
    end record;

    function linkruncca_feature_empty_val return linkruncca_feature_t;
    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t;
    function linkruncca_feature_merge(a: linkruncca_feature_t; b: linkruncca_feature_t) return linkruncca_feature_t;

    function feature2bbox(a: linkruncca_feature_t) return bbox_t;
end;

package body vhdl_linkruncca_pkg is
    function feature2bbox(a: linkruncca_feature_t) return bbox_t is
        variable r: bbox_t;
    begin
        r.x_left := to_integer(a.x_left);
        r.x_right := to_integer(a.x_right);

        if a.n_seg1_sum = 0 then
            -- Segment 0 only
            r.y_top := to_integer(a.y_top_seg0);
            r.y_bottom := to_integer(a.y_bottom_seg0);
        elsif a.n_seg0_sum = 0 then
            -- Segment 1 only
            r.y_top := to_integer(a.y_top_seg1) + y_low_size;
            r.y_bottom := to_integer(a.y_bottom_seg1) + y_low_size;
        else
            if a.y_top_seg0 /= 0 then
                -- Segment 0 is the first segment.
                assert a.y_bottom_seg0 = y_low_max severity error;
                assert a.y_top_seg1 = 0 severity error;
                r.y_top := to_integer(a.y_top_seg0);
                r.y_bottom := to_integer(a.y_bottom_seg1) + y_low_size;
            elsif a.y_top_seg1 /= 0 then
                -- Segment 1 is the first segment.
                assert a.y_bottom_seg1 = y_low_max severity error;
                assert a.y_top_seg0 = 0 severity error;
                r.y_top := to_integer(a.y_top_seg1) + y_low_size;
                r.y_bottom := to_integer(a.y_bottom_seg0);
            else
                if a.y_bottom_seg1 /= y_low_max then
                    -- Y starts from 0 of segment 0, and continues to segment 1 but not to end of segment 1.
                    r.y_top := 0;
                    r.y_bottom := to_integer(a.y_bottom_seg1) + y_low_size;
                elsif a.y_bottom_seg0 /= y_low_max then
                    -- Y starts from 0 of segment 1, and continues to segment 0 but not to end of segment 0.
                    r.y_top := y_low_size;
                    r.y_bottom := to_integer(a.y_bottom_seg0) + 2*y_low_size;
                else
                    -- y_top/bottom covers the whole y_size range.
                    r.y_top := 0;
                    r.y_bottom := y_max;
                end if;
            end if;
        end if;

        return r;
    end;

    function linkruncca_feature_empty_val return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
    begin
        r.x_left := (others => '1');
        r.x_right := (others => '0');
        r.y_top_seg0 := (others => '1');
        r.y_top_seg1 := (others => '1');
        r.y_bottom_seg0 := (others => '0');
        r.y_bottom_seg1 := (others => '0');
        r.x2_sum := (others => '0');
        r.ylow2_sum := (others => '0');
        r.xylow_sum := (others => '0');
        r.x_seg0_sum := (others => '0');
        r.x_seg1_sum := (others => '0');
        r.ylow_seg0_sum := (others => '0');
        r.ylow_seg1_sum := (others => '0');
        r.n_seg0_sum := (others => '0');
        r.n_seg1_sum := (others => '0');

        return r;
    end;

    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
        variable y_msb: std_logic;
        variable y_low: unsigned(y_low_bits-1 downto 0);
    begin
        y_msb := a.y(a.y'high);
        y_low := a.y(a.y'high-1 downto a.y'low);

        r := linkruncca_feature_empty_val;

        r.x_left := a.x;
        r.x_right := a.x;

        if y_msb = '0' then
            r.y_top_seg0 := y_low;
            r.y_bottom_seg0 := y_low;
        else
            r.y_top_seg1 := y_low;
            r.y_bottom_seg1 := y_low;
        end if;
        

        r.x2_sum := resize(a.x*a.x, r.x2_sum);

        r.ylow2_sum := resize(y_low, r.ylow2_sum);
        r.xylow_sum := resize(a.x*y_low, r.xylow_sum);

        if y_msb = '0' then
            r.x_seg0_sum := to_unsigned(1, r.x_seg0_sum);
            r.x_seg1_sum := to_unsigned(0, r.x_seg1_sum);
            r.ylow_seg0_sum := resize(a.y, r.ylow_seg0_sum);
            r.ylow_seg1_sum := to_unsigned(0, r.ylow_seg1_sum);
            r.n_seg0_sum := to_unsigned(1, r.n_seg0_sum);
            r.n_seg1_sum := to_unsigned(0, r.n_seg1_sum);
        else
            r.x_seg0_sum := to_unsigned(0, r.x_seg0_sum);
            r.x_seg1_sum := to_unsigned(1, r.x_seg1_sum);
            r.ylow_seg0_sum := to_unsigned(0, r.ylow_seg0_sum);
            r.ylow_seg1_sum := resize(a.y, r.ylow_seg1_sum);
            r.n_seg0_sum := to_unsigned(0, r.n_seg0_sum);
            r.n_seg1_sum := to_unsigned(1, r.n_seg1_sum);
        end if;

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
        r.y_top_seg0 := min(r.y_top_seg0, b.y_top_seg0);
        r.y_top_seg1 := min(r.y_top_seg1, b.y_top_seg1);
        r.y_bottom_seg0 := max(r.y_bottom_seg0, b.y_bottom_seg0);
        r.y_bottom_seg1 := max(r.y_bottom_seg1, b.y_bottom_seg1);
        r.x2_sum := r.x2_sum + b.x2_sum;

        r.ylow2_sum := r.ylow2_sum + b.ylow2_sum;
        r.xylow_sum := r.xylow_sum + b.xylow_sum;
        r.x_seg0_sum := r.x_seg0_sum + b.x_seg0_sum;
        r.x_seg1_sum := r.x_seg1_sum + b.x_seg1_sum;
        r.ylow_seg0_sum := r.ylow_seg0_sum + b.ylow_seg0_sum;
        r.ylow_seg1_sum := r.ylow_seg1_sum + b.ylow_seg1_sum;
        r.n_seg0_sum := r.n_seg0_sum + b.n_seg0_sum;
        r.n_seg1_sum := r.n_seg1_sum + b.n_seg1_sum;

        return r;
    end;
end;
