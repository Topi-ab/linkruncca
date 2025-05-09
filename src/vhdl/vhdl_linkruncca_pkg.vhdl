library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vhdl_linkruncca_pkg is
    constant x_bits: integer := 8;
    constant y_bits: integer := 8;

    -- This structure holds data from single pixel, which needs to be collected to feature.
    type linkruncca_collect_t is record
        x: unsigned(x_bits-1 downto 0);
        y: unsigned(y_bits-1 downto 0);
    end record;

    -- This structure holds features for single label.
    type linkruncca_feature_t is record
        x_left: unsigned(x_bits-1 downto 0);
        x_right: unsigned(x_bits-1 downto 0);
        y_top: unsigned(y_bits-1 downto 0);
        y_bottom: unsigned(y_bits-1 downto 0);
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

        return r;
    end;

    function linkruncca_feature_collect(a: linkruncca_collect_t) return linkruncca_feature_t is
        variable r: linkruncca_feature_t;
    begin
        r.x_left := a.x;
        r.x_right := a.x;
        r.y_top := a.y;
        r.y_bottom := a.y;

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

