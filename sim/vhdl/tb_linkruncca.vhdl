library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.math_complex.all;
use std.env.all;

entity tb_linkruncca is
    generic(
        X_SIZE: positive := 130;
        Y_SIZE: positive := 130;
        MAX_IMG: positive := 10;
        MODE: integer := 0;
        MODE_PARAM_1: real := 0.25;
        MODE_PARAM_2: real := 0.6
    );
end;

architecture tb of tb_linkruncca is
    constant dut_x_bit: integer := integer(ceil(log2(real(X_SIZE))));
    constant dut_y_bit: integer := integer(ceil(log2(real(Y_SIZE))));
    constant dut_address_bit: integer := dut_x_bit - 1;
    constant dut_data_bit: integer := 2 * (dut_x_bit + dut_y_bit);
    constant dut_latency: integer := 3;

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
    end component;

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
    end record;

    function get_image_pixel(a: image_gen_t) return pixel_t is
        variable s1, s2: integer;
        variable x, y: natural;
        variable rnd: real;
        variable r: pixel_t;
    begin
        r.hard_pixel := '0';

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

        -- report "a.image_number: " & integer'image(a.image_number);
        -- report "s1 - s2: " & integer'image(s1) & " - " & integer'image(s2);

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

    signal dut_res_valid: std_logic;
    signal dut_res_box: std_logic_vector(dut_data_bit-1 downto 0);

    signal verilog_dut_res_valid: std_logic;
    signal verilog_dut_res_box: std_logic_vector(dut_data_bit-1 downto 0);

    signal error_res_valid: std_logic := '0';
    signal error_res_valid_sticky: std_logic := '0';
    signal error_res_box: std_logic := '0';
    signal error_res_box_sticky: std_logic := '0';
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
        for i in 1 to X_SIZE+5 loop
            wait until rising_edge(clk);
        end loop;
        sreset <= '0';
        wait;
    end process;

    pixel_gen_pr: process
        variable pix_gen: image_gen_t;
        variable pix: pixel_t;
    
    begin
        dut_feed_valid <= '1';
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

        dut_feed_valid <= '1';
        for img in 0 to MAX_IMG-1 loop
            pix_gen.image_number := img;
            for y in 0 to Y_SIZE-1 loop
                pix_gen.y := y;
                for x in 0 to X_SIZE-1 loop
                    pix_gen.x := x;
                    pix := get_image_pixel(pix_gen);
                    dut_feed_pix <= pix.hard_pixel;
                    wait until rising_edge(clk);
                end loop;
                dut_feed_valid <= '0';
                wait until rising_edge(clk);
                dut_feed_valid <= '1';
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
            imwidth => X_SIZE,
            imheight => Y_SIZE,
            x_bit => dut_x_bit,
            y_bit => dut_y_bit,
            address_bit => dut_address_bit,
            data_bit => dut_data_bit,
            latency => dut_latency
        )
        port map(
            clk => clk,
            rst => sreset,
            datavalid => dut_feed_valid,
            pix_in => dut_feed_pix,
            datavalid_out => dut_res_valid,
            box_out => dut_res_box
        );
    
    verilog_dut: LinkRunCCA
        generic map(
            imwidth => X_SIZE,
            imheight => Y_SIZE,
            x_bit => dut_x_bit,
            y_bit => dut_y_bit,
            address_bit => dut_address_bit,
            data_bit => dut_data_bit,
            latency => dut_latency
        )
        port map(
            clk => clk,
            rst => sreset,
            datavalid => dut_feed_valid,
            pix_in => dut_feed_pix,
            datavalid_out => verilog_dut_res_valid,
            box_out => verilog_dut_res_box
        );
    
    vhdl_verilog_compare_pr: process(clk)
    begin
        if rising_edge(clk) then
            error_res_valid <= '0';
            error_res_box <= '0';

            if sreset = '0' then
                if dut_res_valid /= verilog_dut_res_valid then
                    error_res_valid <= '1';
                    error_res_valid_sticky <= '1';
                elsif dut_res_valid = '1' then
                    if dut_res_box /= verilog_dut_res_box then
                        error_res_box <= '1';
                        error_res_box_sticky <= '1';
                    end if;
                end if;
                end if;
            end if;
    end process;
end;
