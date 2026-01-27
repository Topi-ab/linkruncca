library ieee;
use ieee.std_logic_1164.all;

package vhdl_linkruncca_cfg_pkg is
    type linkruncca_config_t is record
        x_size: integer;
        y_bits: integer;
    end record;
end;
