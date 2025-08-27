library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.math_complex.all;
use std.env.all;

use work.vhdl_linkruncca_pkg.all;
use work.vhdl_linkruncca_util_pkg.all;
use work.ellipse_generator_pkg.all;

entity tb_linkruncca_linescan is
    generic(
        -- X_SIZE: positive := 130;
        -- Y_SIZE: positive := 130;
        MAX_IMG: positive := 100;
        MODE: integer := 0;
        MODE_PARAM_1: real := 0.225;
        MODE_PARAM_2: real := 0.6
    );
end;

architecture tb of tb_linkruncca_linescan is
    constant dut_latency: integer := 3;

    constant ellipses: ellipse_params_a(0 to 3) := (
        0 => (
            cx => 100.0,
            cy => 100.0,
            a => 63.0,
            b => 12.0,
            theta => 10.0,
            inner_prob => 1.0,
            outer_decay => 8000.0,
            outer_power => 1.0, -- 8000 / 1 has rapid rolldown.
            interior_edge_bias => 0.0,
            seed => 123,
            pix_prob_min => 0.5,
            pix_prob_max => 0.5
        ),
        1 => (
            cx => 100.0,
            cy => 512.0,
            a => 63.0,
            b => 12.0,
            theta => 20.0,
            inner_prob => 1.0,
            outer_decay => 8000.0,
            outer_power => 1.0, -- 8000 / 1 has rapid rolldown.
            interior_edge_bias => 0.0,
            seed => 123,
            pix_prob_min => 0.5,
            pix_prob_max => 0.5
        ),
        2 => (
            cx => 100.0,
            cy => 700.0,
            a => 63.0,
            b => 12.0,
            theta => 30.0,
            inner_prob => 1.0,
            outer_decay => 8000.0,
            outer_power => 1.0, -- 8000 / 1 has rapid rolldown.
            interior_edge_bias => 0.0,
            seed => 123,
            pix_prob_min => 0.5,
            pix_prob_max => 0.5
        ),
        3 => (
            cx => 100.0,
            cy => 1025.0,
            a => 63.0,
            b => 12.0,
            theta => 40.0,
            inner_prob => 1.0,
            outer_decay => 8000.0,
            outer_power => 1.0, -- 8000 / 1 has rapid rolldown.
            interior_edge_bias => 0.0,
            seed => 123,
            pix_prob_min => 0.5,
            pix_prob_max => 0.5
        )
    );

    constant box_bits: integer := 2*x_bits + 2*y_bits;

    component LinkRunCCA is
        generic(
            imwidth: integer := 512;
            imheight: integer := 512;
            x_bit: integer := integer(ceil(log2(real(imwidth))));
            y_bit: integer := integer(ceil(log2(real(imheight))));
            address_bit: integer := x_bit - 1;
            data_bit: integer := 2 * (x_bit + y_bit);
            latency: integer := 3
        );
        port(
            clk: in std_logic;
            rst: in std_logic;
            datavalid: in std_logic;
            pix_in: in std_logic;
            datavalid_out: out std_logic;
            box_out: out std_logic_vector(data_bit - 1 downto 0)
        );
    end component;signal valid_d1: std_logic;

    type image_gen_t is record
        seed_1: integer;
        seed_2: integer;
        image_number: natural;
        mode: integer;
        mode_param_1: real;
        mode_param_2: real;
        x: natural;
        y: natural;
    end record;

    type pixel_t is record
        hard_pixel: std_logic;
        x: natural;
        y: natural;
    end record;

    function get_image_pixel(a: image_gen_t) return pixel_t is
        variable s1, s2: integer;
        variable x, y: natural;
        variable rnd: real;
        variable r: pixel_t;
    begin
        r.hard_pixel := '0';
        r.x := a.x;
        r.y := a.y;

        s1 := a.seed_1;
        s2 := a.seed_2;

        s1 := s1 + a.image_number;
        s2 := s2 + a.image_number;
        uniform(s1, s2, rnd);
        s1 := s1 + a.x;
        s2 := s2 + a.x;
        uniform(s1, s2, rnd);
        s1 := s1 + a.y;
        s2 := s2 + a.y;

        for i in 0 to 100 loop
            uniform(s1, s2, rnd);
        end loop;

        uniform(s1, s2, rnd);
        if rnd < a.mode_param_1 then
            r.hard_pixel := '1';
        else
            r.hard_pixel := '0';
        end if;

        return r;
    end;

    signal clk: std_logic;
    signal sreset: std_logic;

    signal dut_feed_valid: std_logic;
    signal dut_feed_pix: std_logic;
    signal dut_feed_pix_meta: pixel_t;
    signal dut_feed_pix_data: linkruncca_collect_t;
    

    signal dut_res_valid: std_logic;
    signal dut_res_data: linkruncca_feature_t;
    signal dut_bbox_data: bbox_t;

    signal verilog_dut_res_valid: std_logic;
    signal verilog_dut_res_box: std_logic_vector(box_bits-1 downto 0);
    signal verilog_bbox_data: bbox_t;

    signal error_res_valid: std_logic := '0';
    signal error_res_valid_sticky: std_logic := '0';
    signal error_res_box: std_logic := '0';
    signal error_res_box_sticky: std_logic := '0';

    signal dut_res_ellipses: resolved_ellipse_t;
begin
    clk_pr: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    rst_pr: process
    begin
        sreset <= '1';
        for i in 1 to x_size+5 loop
            wait until rising_edge(clk);
        end loop;
        sreset <= '0';
        wait;
    end process;

    pixel_gen_pr: process
        variable pix_gen: image_gen_t;
        variable pix: pixel_t;
        variable full_y_counter: integer;
        variable hard_pix: std_logic;
    begin
        dut_feed_valid <= '0';
        dut_feed_pix <= '0';

        pix_gen.seed_1 := 12;
        pix_gen.seed_2 := 2345;
        pix_gen.image_number := 0;
        pix_gen.mode := 0;
        pix_gen.mode_param_1 := MODE_PARAM_1;
        pix_gen.mode_param_2 := MODE_PARAM_2;
        pix_gen.x := 0;
        pix_gen.y := 0;

        wait until rising_edge(clk) and sreset = '0';

        full_y_counter := 0;

        dut_feed_valid <= '1';
        for img in 0 to MAX_IMG-1 loop
            pix_gen.image_number := img;
            for y in 0 to y_size-1 loop
                pix_gen.y := y;
                for x in 0 to x_size-1 loop
                    pix_gen.x := x;
                    -- pix := get_image_pixel(pix_gen);
                    -- dut_feed_pix <= pix.hard_pixel;
                    -- dut_feed_pix_data.in_label <= pix.hard_pixel;
                    hard_pix := '0';
                    for e in ellipses'range loop
                        hard_pix := hard_pix or ellipse_pixel(x, full_y_counter, img, ellipses(e));
                    end loop;
                    dut_feed_pix <= hard_pix;
                    dut_feed_pix_data.in_label <= hard_pix;
                    dut_feed_pix_data.x <= to_unsigned(x, dut_feed_pix_data.x);
                    dut_feed_pix_data.y <= to_unsigned(y, dut_feed_pix_data.y);
                    wait until rising_edge(clk);
                end loop;
                dut_feed_valid <= '0';
                wait until rising_edge(clk);
                dut_feed_valid <= '1';

                full_y_counter := full_y_counter + 1;
            end loop;
            dut_feed_valid <= '0';
            for i in 1 to 15 loop
                wait until rising_edge(clk);
            end loop;
            dut_feed_valid <= '1';
        end loop;

        dut_feed_valid <= '0';

        wait for 1 us;
        assert error_res_valid_sticky = '0' report "vhdl and verilog models did not agree on res_valid" severity failure;
        assert error_res_box_sticky = '0' report "vhdl and verilog models did not agree on res_box" severity failure;
        finish(0);
        wait;
    end process;

    vhdl_dut: entity work.vhdl_linkruncca
        generic map(
            imwidth => x_size,
            imheight => y_size
        )
        port map(
            clk => clk,
            rst => sreset,
            datavalid => dut_feed_valid or sreset,
            pix_in => dut_feed_pix_data,
            res_valid_out => dut_res_valid,
            res_data_out => dut_res_data
        );

    process(all)
    begin
        dut_res_ellipses <= resolve_ellipse(dut_res_data);
    end process;

    process(all)
    begin
        dut_bbox_data <= feature2bbox(dut_res_data);
    end process;
    
    verilog_dut: LinkRunCCA
        generic map(
            imwidth => x_size,
            imheight => y_size,
            x_bit => x_bits,
            y_bit => y_bits,
            address_bit => mem_add_bits,
            data_bit => box_bits,
            latency => dut_latency
        )
        port map(
            clk => clk,
            rst => sreset,
            datavalid => dut_feed_valid or sreset,
            pix_in => dut_feed_pix,
            datavalid_out => verilog_dut_res_valid,
            box_out => verilog_dut_res_box
        );
    
    process(all)
    begin
        verilog_bbox_data.x_left <= to_integer(unsigned(verilog_dut_res_box(box_bits - 1 downto box_bits - x_bits)));
        verilog_bbox_data.x_right <= to_integer(unsigned(verilog_dut_res_box(box_bits - x_bits - 1 downto 2*y_bits)));
        verilog_bbox_data.y_top <= to_integer(unsigned(verilog_dut_res_box(2*y_bits - 1 downto y_bits)));
        verilog_bbox_data.y_bottom <= to_integer(unsigned(verilog_dut_res_box(y_bits-1 downto 0)));
    end process;

    vhdl_verilog_compare_pr: process(clk)
    begin
        if rising_edge(clk) then
            error_res_valid <= '0';
            error_res_box <= '0';

            if sreset = '0' then
                if dut_res_valid = '1' and verilog_dut_res_valid = '0' then
                    error_res_valid <= '1';
                    error_res_valid_sticky <= '1';
                elsif dut_res_valid = '1' then
                    if dut_bbox_data /= verilog_bbox_data then
                        error_res_box <= '1';
                        error_res_box_sticky <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
end;
