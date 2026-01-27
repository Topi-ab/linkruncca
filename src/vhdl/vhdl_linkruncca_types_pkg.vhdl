library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vhdl_linkruncca_types_pkg is
    -- Unconstrained record types for ports.
    type linkruncca_collect_t is record
        in_label: std_logic;
        has_red: std_logic;
        has_green: std_logic;
        has_blue: std_logic;
        x: unsigned;
        y: unsigned;
    end record;

    type linkruncca_feature_t is record
        has_red: std_logic;
        has_green: std_logic;
        has_blue: std_logic;
        x_left: unsigned;
        x_right: unsigned;
        y_top: unsigned;
        y_bottom: unsigned;
    end record;
end;

package body vhdl_linkruncca_types_pkg is
end;
