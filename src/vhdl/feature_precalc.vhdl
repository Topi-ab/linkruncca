library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_linkruncca_util_pkg.all;
use work.vhdl_linkruncca_pkg.all;

entity feature_precalc is
    port(
        clk_in: in std_logic;

        collect_in: in linkruncca_collect_t;
        feature_out: out linkruncca_feature_t
    );
end;

architecture rtl of feature_precalc is
begin
    process(all)
    begin
        feature_out <= linkruncca_feature_collect(collect_in);
    end process;
end;
