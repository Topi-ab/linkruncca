library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.vhdl_linkruncca_util_pkg.all;

package vhdl_linkruncca_pkg is
    -- USER PARAMETERS =>

    constant x_size: integer := 400;
    constant y_bits: integer := 16;
    
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

    type resolved_ellipse_t is record
        cx: real;
        cy: real;
        major: real;
        minor: real;
        theta: real;
        pixels: real;

        sum_x: real;
        sum_y: real;
        sum_xx: real;
        sum_yy: real;
        sum_xy: real;
    end record;

    function resolve_ellipse(a: linkruncca_feature_t) return resolved_ellipse_t;

    function linkruncca_feature_empty_val return linkruncca_feature_t;
    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t;
    function linkruncca_feature_merge(a: linkruncca_feature_t; b: linkruncca_feature_t) return linkruncca_feature_t;

    function feature2bbox(a: linkruncca_feature_t) return bbox_t;
end;

package body vhdl_linkruncca_pkg is
    -- This function is used in simulation only, to verify functionality (bounding box result) against the Golden model.
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
                r.y_top := to_integer(a.y_top_seg1) - y_low_size;
                r.y_bottom := to_integer(a.y_bottom_seg0);
            else
                if a.y_bottom_seg1 /= y_low_max then
                    -- Y starts from 0 of segment 0, and continues to segment 1 but not to end of segment 1.
                    r.y_top := 0;
                    r.y_bottom := to_integer(a.y_bottom_seg1) + y_low_size;
                elsif a.y_bottom_seg0 /= y_low_max then
                    -- Y starts from 0 of segment 1, and continues to segment 0 but not to end of segment 0.
                    r.y_top := to_integer(a.y_top_seg1) - y_low_size;
                    r.y_bottom := to_integer(a.y_bottom_seg0);
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

        r.ylow2_sum := resize(y_low*y_low, r.ylow2_sum);
        r.xylow_sum := resize(a.x*y_low, r.xylow_sum);

        if y_msb = '0' then
            r.x_seg0_sum := resize(a.x, r.x_seg0_sum);
            r.x_seg1_sum := to_unsigned(0, r.x_seg1_sum);
            r.ylow_seg0_sum := resize(a.y, r.ylow_seg0_sum);
            r.ylow_seg1_sum := to_unsigned(0, r.ylow_seg1_sum);
            r.n_seg0_sum := to_unsigned(1, r.n_seg0_sum);
            r.n_seg1_sum := to_unsigned(0, r.n_seg1_sum);
        else
            r.x_seg0_sum := to_unsigned(0, r.x_seg0_sum);
            r.x_seg1_sum := resize(a.x, r.x_seg1_sum);
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

    function to_real(a: unsigned) return real is
        variable r: real;
    begin
        r := 0.0;
        for i in a'high downto a'low loop
            r := 2.0 * r;
            if a(i) = '1' then
                r := r + 1.0;
            end if;
        end loop;

        return r;
    end;

    function resolve_ellipse(a: linkruncca_feature_t) return resolved_ellipse_t is
        variable r: resolved_ellipse_t;
        variable sum_x: real;
        variable sum_y: real;
        variable sum_xx: real;
        variable sum_yy: real;
        variable sum_xy: real;
        variable pixels: real;
        variable geom_case: integer;
        variable x_mean: real;
        variable y_mean: real;
        variable u20: real;
        variable u02: real;
        variable u11: real;
        variable l_left: real;
        variable l_right: real;
        variable l1: real;
        variable l2: real;
    begin
        pixels := to_real(a.n_seg0_sum) + to_real(a.n_seg1_sum);
        if pixels = 0.0 then
            return r;
        end if;

        sum_x := to_real(a.x_seg0_sum) + to_real(a.x_seg1_sum);
        sum_xx := to_real(a.x2_sum);

        geom_case := 0;

        if a.n_seg0_sum /= 0 and a.n_seg1_sum = 0 then
            -- case 1 - within segment 0
            geom_case := 1;
        elsif a.n_seg0_sum = 0 and a.n_seg1_sum /= 0 then
            -- case 2 - within segment 1
            geom_case := 2;
        else
            if a.y_top_seg0 /= 0 and a.y_top_seg1 = 0 then
                -- case 3 - within starts in segment 0, wraps over to segment 1.
                geom_case := 3;
            elsif a.y_top_seg0 = 0 and a.y_top_seg1 /= 0 then
                -- case 4 - within starts in segment 1, wraps over to segment 0.
                geom_case := 4;
            else
            end if;
        end if;

        case geom_case is
            when 1 | 2 | 3 =>
                sum_y := to_real(a.ylow_seg0_sum) + to_real(a.ylow_seg1_sum) + real(y_low_size)*to_real(a.n_seg1_sum);
                sum_yy := to_real(a.ylow2_sum) + real(y_size)*to_real(a.ylow_seg1_sum) + real(y_low_size)**2*to_real(a.n_seg1_sum);
                sum_xy := to_real(a.xylow_sum) + real(y_low_size)*to_real(a.x_seg1_sum);
            when 4 =>
                sum_y := to_real(a.ylow_seg0_sum) + to_real(a.ylow_seg1_sum) - real(y_low_size)*to_real(a.n_seg1_sum);
                sum_yy := to_real(a.ylow2_sum) - real(y_size)*to_real(a.ylow_seg1_sum) + real(y_low_size)**2*to_real(a.n_seg1_sum);
                sum_xy := to_real(a.xylow_sum) - real(y_low_size)*to_real(a.x_seg1_sum);
            when others =>
        end case;

        x_mean := sum_x / pixels;
        y_mean := sum_y / pixels;
        u20 := sum_xx / pixels - x_mean**2;
        u02 := sum_yy / pixels - y_mean**2;
        u11 := sum_xy / pixels - x_mean*y_mean;
        l_left := (u20 + u02)/2.0;
        l_right := sqrt(((u20 - u02)/2.0)**2 + u11**2);
        l1 := l_left + l_right;
        l2 := l_left - l_right;

        r.pixels := pixels;
        r.cx := x_mean;
        r.cy := y_mean;
        r.major := 2.0*sqrt(l1);
        r.minor := 2.0*sqrt(l2);
        r.theta := 0.5*arctan(2.0*u11, u20 - u02) / MATH_PI * 180.0;

        r.sum_x := sum_x;
        r.sum_y := sum_y;
        r.sum_xx := sum_xx;
        r.sum_yy := sum_yy;
        r.sum_xy := sum_xy;
        return r;
    end;
end;
