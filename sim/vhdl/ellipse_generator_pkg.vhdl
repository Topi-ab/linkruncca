library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ellipse_generator_pkg is
    type ellipse_params_t is record
        cx: real;    -- center x
        cy: real;    -- center y
        a: real;     -- semi-major axis length (>= b > 0)
        b: real;     -- semi-minor axis length (> 0)
        theta: real; -- rotation (degrees), CCW

        inner_prob: real;         -- [0,1], inclusion probability for r<=1
        outer_decay: real;        -- >0, steeper drop outside
        outer_power: real;        -- >=1, shape of decay (2.0 = quadratic)
        interior_edge_bias: real; -- ~[-1..1], + biases density toward boundary
        seed: integer;            -- main seed used to derive per-pixel seeds
        pix_prob_min: real;       -- min value of randomized value for pixel
        pix_prob_max: real;       -- max value of randomized value for pixel
    end record;

    type ellipse_params_a is array(integer range <>) of ellipse_params_t;

    pure function ellipse_pixel(x, y: integer; frame: integer; p: ellipse_params_t) return std_logic;
    -- pure function coordinate_rnd(x: integer; y: integer; frame: integer; seed: integer) return real;
    -- pure function normalized_radius(x, y : integer; p : ellipse_params_t) return real;
end;

package body ellipse_generator_pkg is
    pure function coordinate_rnd(x: integer; y: integer; frame: integer; p: ellipse_params_t) return real is
        variable s1, s2: integer;
        variable seed: integer;
        variable u: real;
    begin
        seed := p.seed;
        s1 := frame;
        s2 := seed;
        uniform(s1, s2, u);
        s1 := (s1 + x) mod (2**31 - 1);
        s2 := (s2 + x) mod (2**31 - 1);
        uniform(s1, s2, u);
        s1 := (s1 + y) mod (2**31 - 1);
        s2 := (s2 + y) mod (2**31 - 1);
        for i in 0 to 30 loop
            uniform(s1, s2, u);
        end loop;
        u := u * (p.pix_prob_max - p.pix_prob_min) + p.pix_prob_min;
        return u;
    end;

    function clamp01(v : real) return real is
    begin
        if v < 0.0 then
            return 0.0;
        elsif v > 1.0 then
            return 1.0;
        else
            return v;
        end if;
    end function;

    pure function normalized_radius(x, y : integer; p : ellipse_params_t) return real is
        variable dx, dy: real;
        variable c, s: real;
        variable xp, yp: real;
    begin
        assert (p.a > 0.0) and (p.b > 0.0) report "Ellipse axes must be positive!" severity failure;
        dx := real(x) - p.cx;
        dy := real(y) - p.cy;
        c  := cos(p.theta/180.0*MATH_PI);
        s  := sin(p.theta/180.0*MATH_PI);
        xp :=  dx * c + dy * s;
        yp := -dx * s + dy * c;
        return sqrt((xp / p.a)**2 + (yp / p.b)**2);
    end function;

    pure function pixel_prob(x, y: integer; p: ellipse_params_t) return real is
        variable r: real;
        variable inner_p: real;
        variable prob: real;
        variable t, d, adj: real;
        variable power_used: real;
        variable decay_used: real;
    begin
        power_used := p.outer_power;
        if p.outer_power < 1.0 then
            power_used := 1.0;
        end if;

        decay_used := p.outer_decay;
        if p.outer_decay < 0.0 then
            decay_used := 0.0;
        end if;

        r := normalized_radius(x, y, p);
        inner_p := clamp01(p.inner_prob);

        if r <= 1.0 then
            if abs(p.interior_edge_bias) < 1.0e-9 then
                return inner_p;
            else
                -- bias density inside: + pushes toward boundary, - toward center
                t := r; -- 0 center .. 1 boundary
                adj := 1.0 + 0.5*p.interior_edge_bias*(2.0*t - 1.0);
                return clamp01(inner_p * adj);
            end if;
        else
            d    := r - 1.0;  -- >= 0
            prob := inner_p * exp(-decay_used * (d**power_used));
            return clamp01(prob);
        end if;
    end function;

    pure function ellipse_pixel(x, y: integer; frame: integer; p: ellipse_params_t) return std_logic is
        variable ellipse_prob: real;
        variable coordinate_prob: real;
    begin
        ellipse_prob := pixel_prob(x, y, p);
        coordinate_prob := coordinate_rnd(x, y, frame, p);
        -- coordinate_prob := 0.5;

        if y = 100 and x > 75 and x < 125 then
            report "x: " & integer'image(x) & "   y: " & integer'image(y) & "   frame: " & integer'image(frame);
            
            report "ellipse_prob: " & real'image(ellipse_prob) & 
                "coordinate_prob: " & real'image(coordinate_prob);
        end if;

        if ellipse_prob >= coordinate_prob then
            return '1';
        end if;
        return '0';
    end;
end;
