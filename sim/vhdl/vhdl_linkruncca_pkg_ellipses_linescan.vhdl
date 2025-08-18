library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package vhdl_linkruncca_pkg is
    constant x_size: integer := 200;
    -- constant y_size: integer := 200;
    constant y_bits: integer := 8;


    function fit(a: unsigned; extra_bits: natural := 0) return unsigned;
    function fit(a: integer; extra_bits: natural := 0) return unsigned;
    function sum_x(x1: integer; x2: integer) return integer;
    function sum_x(x1: natural; x2: natural) return unsigned;
    function sum_x2(x1: integer; x2: integer) return integer;
    function sum_x2(x1: integer; x2: integer) return unsigned;
    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return integer;
    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return unsigned;
    function max2bits(a: unsigned) return integer;
    function max2bits(a: integer) return integer;


    -- constant pix_count: integer := x_size*y_size;

    ----constant x_bits: integer := integer(ceil(log2(real(x_size))));
    constant x_bits: integer := max2bits(x_size-1);
    -- constant y_bits: integer := integer(ceil(log2(real(y_size))));
    -- constant pix_count_bits: integer := integer(ceil(log2(real(pix_count))));

    constant x_max: integer := x_size - 1;
    constant y_low_bits: integer := y_bits - 1;
    constant y_size: integer := 2**y_bits;
    constant y_max: integer := y_size - 1;
    constant y_low_size: integer := 2**y_low_bits;
    constant y_low_max: integer := y_low_size - 1;
    constant n_seg_sum_bits: integer := max2bits(fit(x_size) * fit(y_low_size));

    constant mem_add_bits: integer := x_bits-1;

    constant box_bits: integer := 2*x_bits + 2*y_bits;

    -- constant x_sum_bits: integer := x_bits + pix_count_bits;
    -- constant y_sum_bits: integer := y_bits + pix_count_bits;
    ----constant x2_sum_bits: integer := 2*x_bits + pix_count_bits;
    -- constant y2_sum_bits: integer := 2*y_bits + pix_count_bits;
    -- constant xy_sum_bits: integer := x_bits+y_bits + pix_count_bits;

    constant x2_sum_bits: integer := max2bits(unsigned'(sum_x2(0, x_max))*y_size);
    -- constant ylow2_sum_bits: integer := 2*ylow_bits + n_seg_sum_bits;
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
        --pix_count: unsigned(pix_count_bits-1 downto 0);
        -- x_sum: unsigned(x_sum_bits-1 downto 0);
        x2_sum: unsigned(x2_sum_bits-1 downto 0);
        ylow2_sum: unsigned(ylow2_sum_bits-1 downto 0);
        xylow_sum: unsigned(xylow_sum_bits-1 downto 0);
        x_seg0_sum: unsigned(x_seg_sum_bits-1 downto 0);
        x_seg1_sum: unsigned(x_seg_sum_bits-1 downto 0);
        -- y_sum: unsigned(y_sum_bits-1 downto 0);
        -- y2_sum: unsigned(y2_sum_bits-1 downto 0);
        -- xy_sum: unsigned(xy_sum_bits-1 downto 0);
        ylow_seg0_sum: unsigned(ylow_seg_sum_bits-1 downto 0);
        ylow_seg1_sum: unsigned(ylow_seg_sum_bits-1 downto 0);
        n_seg0_sum: unsigned(n_seg_sum_bits-1 downto 0);
        n_seg1_sum: unsigned(n_seg_sum_bits-1 downto 0);
    end record;

    function linkruncca_feature_empty_val return linkruncca_feature_t;
    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t;
    function linkruncca_feature_merge(a: linkruncca_feature_t; b: linkruncca_feature_t) return linkruncca_feature_t;
    function min(a: unsigned; b: unsigned) return unsigned;
    function max(a: unsigned; b: unsigned) return unsigned;
    -- function feature2bbox(a: linkruncca_feature_t) return bbox_t;
end;

package body vhdl_linkruncca_pkg is
    /*function feature2bbox(a: linkruncca_feature_t) return bbox_t is
        variable r: bbox_t;
    begin
        r.x_left := resize(a.x_left, r.x_left);
        r.x_right := resize(a.x_right, r.x_right);

        if a.n_seg1_sum = 0 then
            -- Segment 0 only
            r.y_top := resize(a.y_top_seg0, r.y_top);
            r.y_bottom := resize(a.y_bottom_seg0, r.y_bottom);
        elsif a.n_seg0_sum = 0 then
            -- Segment 1 only
            r.y_top := resize(a.y_top_seg1, r.y_top) + y_low_size;
            r.y_bottom := resize(a.y_bottom_seg1, r.y_bottom) + y_low_size;
        else
            if a.y_top_seg0 /= 0 then
                -- Segment 0 is the first segment.
                assert a.y_bottom_seg0 = y_low_max severity failure;
                assert a.y_top_seg1 = 0 severity failure;
                r.y_top := resize(a.y_top_seg0, r.y_top);
                r.y_bottom := resize(a.y_bottom_seg1, r.y_bottom) + y_low_size;
            elsif a.y_top_seg1 /= 0
                -- Segment 1 is the first segment.
                assert a.y_bottom_seg1 = y_low_max severity failure;
                assert a.y_top_seg0 = 0 severity failure;
                r.y_top := resize(a.y_top_seg1, r.y_top) + y_low_size;
                r.y_bottom := resize(a.y_bottom_seg0, r.y_bottom);
            else
            end if;
        end if;

        return r;
    end;*/

    function fit(a: unsigned; extra_bits: natural := 0) return unsigned is
    begin
        return resize(a, max2bits(a+extra_bits));
    end;

    function fit(a: integer; extra_bits: natural := 0) return unsigned is
    begin
        return fit(to_unsigned(a, max2bits(a)), max2bits(a)+extra_bits);
    end;

    function sum_x(x1: integer; x2: integer) return integer is
    begin
        assert x2 >= x1 severity failure;
        return (x2-x1+1)*(x1+x2)/2;
    end;

    function sum_x(x1: natural; x2: natural) return unsigned is
    begin
        assert x2 >= x1 severity failure;
        return fit((fit(x2, 2)-fit(x1, 2)+1)*(fit(x1, 1)+fit(x2, 1))/2);
    end;

    function sum_x2(x1: integer; x2: integer) return integer is
    begin
        return x2*(x1+1)*(2*x2+1)/6 - (x1-1)*x1*(2*x1-1)/6;
    end;

    function sum_x2(x1: integer; x2: integer) return unsigned is
    begin
        return fit(fit(x2)*(fit(x1, 1)+1)*(fit(2)*fit(x2, 1)+1)/6 - (fit(x1)-1)*fit(x1)*(fit(2)*fit(x1)-1)/6);
    end;

    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return integer is
    begin
        return sum_x(x1, x2) * sum_x(y1, y2);
    end;

    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return unsigned is
    begin
        return fit(unsigned'(sum_x(x1, x2)) * unsigned'(sum_x(y1, y2)));
    end;

    function max2bits(a: unsigned) return integer is
        constant x: unsigned(a'length-1 downto 0) := a;
    begin
        for n in x'high downto x'low loop
            if x(n) = '1' then
                return n+1;
            end if;
        end loop;

        return 0;
    end;

    function max2bits(a: integer) return integer is
    begin
        return max2bits(to_unsigned(a, 32));
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
        -- r.pix_count := (others => '0');
        -- r.x_sum := (others => '0');
        -- r.y_sum := (others => '0');
        r.x2_sum := (others => '0');
        -- r.y2_sum := (others => '0');
        -- r.xy_sum := (others => '0');
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
        

        -- r.pix_count := to_unsigned(1, r.pix_count);
        -- r.x_sum := resize(a.x, r.x_sum);
        -- r.y_sum := resize(a.y, r.y_sum);
        r.x2_sum := resize(a.x*a.x, r.x2_sum);
        -- r.y2_sum := resize(a.y*a.y, r.y2_sum);
        -- r.xy_sum := resize(a.x*a.y, r.xy_sum);

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
        -- r.pix_count := r.pix_count + b.pix_count;
        -- r.x_sum := r.x_sum + b.x_sum;
        -- r.y_sum := r.y_sum + b.y_sum;
        r.x2_sum := r.x2_sum + b.x2_sum;
        -- r.y2_sum := r.y2_sum + b.y2_sum;
        -- r.xy_sum := r.xy_sum + b.xy_sum;

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
