library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_linkruncca_cfg_pkg.all;
use work.vhdl_linkruncca_types_pkg.all;
use work.vhdl_linkruncca_util_pkg.all;

entity feature_precalc is
    generic(
        cfg: linkruncca_config_t
    );
    port(
        clk_in: in std_logic;

        collect_in: in linkruncca_collect_t;
        feature_out: out linkruncca_feature_t
    );
end;

architecture rtl of feature_precalc is
    package linkruncca_pkg is new work.vhdl_linkruncca_pkg
        generic map(
            cfg => cfg
        );
    use linkruncca_pkg.all;

begin
    process(all)
    begin
        feature_out <= linkruncca_feature_collect(collect_in);
    end process;
end;
