library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package vhdl_linkruncca_util_pkg is
    function fit(a: unsigned; extra_bits: natural := 0) return unsigned;
    function fit(a: integer; extra_bits: natural := 0) return unsigned;
    function sum_x(x1: integer; x2: integer) return integer;
    function sum_x(x1: natural; x2: natural) return unsigned;
    function sum_x2(x1: integer; x2: integer) return integer;
    function sum_x2(x1: integer; x2: integer) return unsigned;
    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return integer;
    function sum_xy(x1: integer; x2: integer; y1: integer; y2: integer) return unsigned;
    function max2bits(a: integer) return integer;
    function max2bits(a: unsigned) return integer;
    function min(a: unsigned; b: unsigned) return unsigned;
    function max(a: unsigned; b: unsigned) return unsigned;

    type bbox_t is record
        x_left: integer;
        x_right: integer;
        y_top: integer;
        y_bottom: integer;
    end record;
end;

package body vhdl_linkruncca_util_pkg is
    function fit(a: unsigned; extra_bits: natural := 0) return unsigned is
        variable sz: integer;
    begin
        sz := max2bits(a) + extra_bits;
        if a = 0 then
            sz := extra_bits + 1;
        end if;
        if sz /= 0 then
            return resize(a, sz);
        else
            return resize(a, 1);
        end if;
    end;

    function fit(a: integer; extra_bits: natural := 0) return unsigned is
    begin
        assert a = to_integer(fit(to_unsigned(a, max2bits(a)), extra_bits)) severity failure;
        return fit(to_unsigned(a, max2bits(a)), extra_bits);
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
        return x2*(x2+1)*(2*x2+1)/6 - (x1-1)*x1*(2*x1-1)/6;
    end;

    function sum_x2(x1: integer; x2: integer) return unsigned is
    begin
        return fit(fit(x2)*(fit(x2, 1)+1)*(fit(2)*fit(x2, 1)+1)/6 - (fit(x1)-1)*fit(x1)*(fit(2)*fit(x1)-1)/6);
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
