set fpga_part "xc7k160tffg676-3"
set proj_name "tb_verilog_vivado_comparator"
set proj_dir ../../vivado/xpr
set top_module "vhdl_linkruncca"

# Delete old project from disk (if any):
foreach item [glob -nocomplain -directory $proj_dir *] {
    file delete -force -- $item
}


# Create project
create_project $proj_name $proj_dir -part $fpga_part

# Add VHDL files:
add_files ../../sim/vhdl/vhdl_linkruncca_pkg_ellipses.vhdl

#add_files ../vhdl/vhdl_linkruncca_pkg.vhdl
add_files ../vhdl/vhdl_equivalence_resolver.vhdl
add_files ../vhdl/vhdl_feature_accumulator.vhdl
add_files ../vhdl/vhdl_holes_filler.vhdl
add_files ../vhdl/vhdl_row_buf.vhdl
add_files ../vhdl/vhdl_table_ram_add.vhdl
add_files ../vhdl/vhdl_table_ram_data.vhdl
add_files ../vhdl/vhdl_table_reader.vhdl
add_files ../vhdl/vhdl_window.vhdl
add_files ../vhdl/vhdl_linkruncca.vhdl

set_property file_type {VHDL 2008} [get_files ../../sim/vhdl/vhdl_linkruncca_pkg_ellipses.vhdl]

#set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_linkruncca_pkg.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_equivalence_resolver.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_feature_accumulator.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_holes_filler.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_row_buf.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_table_ram_add.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_table_ram_data.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_table_reader.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_window.vhdl]
set_property file_type {VHDL 2008} [get_files ../vhdl/vhdl_linkruncca.vhdl]

# Add verilog files
add_files ../verilog/cca.vh
add_files ../verilog/equivalence_resolver.v
add_files ../verilog/feature_accumulator.v
add_files ../verilog/holes_filler.v
add_files ../verilog/row_buf.v
add_files ../verilog/table_ram.v
add_files ../verilog/table_reader.v
add_files ../verilog/window.v
add_files ../verilog/linkruncca.v

# Add constraints:
add_files -fileset constrs_1 timing.sdc

# Set top module:
set_property top $top_module [current_fileset]

# Add simulation VHDL files:
add_files -fileset sim_1 ../../sim/vhdl/tb_linkruncca.vhdl
set_property file_type {VHDL 2008} [get_files ../../sim/vhdl/tb_linkruncca.vhdl]

# Save the project:
# save_project_as $proj_name $proj_dir
