library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_linkruncca_cfg_pkg.all;
use work.vhdl_linkruncca_types_pkg.all;
use work.vhdl_linkruncca_util_pkg.all;

package vhdl_linkruncca_pkg is
    generic(
        cfg: linkruncca_config_t
    );

    constant x_size: integer := cfg.x_size;
    constant y_bits: integer := cfg.y_bits;
    constant x_bits: integer := max2bits(x_size - 1);

    constant box_bits: integer := 2*x_bits + 2*y_bits;
    constant mem_add_bits: integer := x_bits - 1;

    subtype linkruncca_collect_t_c is linkruncca_collect_t(
        x(x_bits-1 downto 0),
        y(y_bits-1 downto 0)
    );
    subtype linkruncca_feature_t_c is linkruncca_feature_t(
        x_left(x_bits-1 downto 0),
        x_right(x_bits-1 downto 0),
        y_top(y_bits-1 downto 0),
        y_bottom(y_bits-1 downto 0)
    );

    function linkruncca_feature_empty_val return linkruncca_feature_t_c;
    function linkruncca_feature_collect(a: linkruncca_collect_t_c) return linkruncca_feature_t_c;
    function linkruncca_feature_collect(a: linkruncca_collect_t_c; neighbour: pixel_neighbour_t) return linkruncca_feature_t_c;
    function linkruncca_feature_merge(a: linkruncca_feature_t_c; b: linkruncca_feature_t_c) return linkruncca_feature_t_c;
    function umin(a: unsigned; b: unsigned) return unsigned;
    function umax(a: unsigned; b: unsigned) return unsigned;
end;

package body vhdl_linkruncca_pkg is
    function linkruncca_feature_empty_val return linkruncca_feature_t_c is
        variable r: linkruncca_feature_t_c;
    begin
        r.x_left := (others => '1');
        r.x_right := (others => '0');
        r.y_top := (others => '1');
        r.y_bottom := (others => '0');
        r.has_red := '0';
        r.has_green := '0';
        r.has_blue := '0';

        return r;
    end;

    function linkruncca_feature_collect(a: linkruncca_collect_t_c) return linkruncca_feature_t_c is
        variable r: linkruncca_feature_t_c;
    begin
        r.x_left := a.x;
        r.x_right := a.x;
        r.y_top := a.y;
        r.y_bottom := a.y;
        r.has_red := a.has_red;
        r.has_green := a.has_green;
        r.has_blue := a.has_blue;

        return r;
    end;

    function linkruncca_feature_collect(
            a: linkruncca_collect_t_c;
            neighbour: pixel_neighbour_t
        ) return linkruncca_feature_t_c is
    begin
        return linkruncca_feature_collect(a);
    end;

    function linkruncca_feature_merge(
            a: linkruncca_feature_t_c;
            b: linkruncca_feature_t_c
        ) return linkruncca_feature_t_c is
        variable r: linkruncca_feature_t_c;
    begin
        r := a;

        r.x_left := umin(r.x_left, b.x_left);
        r.x_right := umax(r.x_right, b.x_right);
        r.y_top := umin(r.y_top, b.y_top);
        r.y_bottom := umax(r.y_bottom, b.y_bottom);
        r.has_red := r.has_red or b.has_red;
        r.has_green := r.has_green or b.has_green;
        r.has_blue := r.has_blue or b.has_blue;

        return r;
    end;

    function umin(a: unsigned; b: unsigned) return unsigned is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end;

    function umax(a: unsigned; b: unsigned) return unsigned is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end;
end;
