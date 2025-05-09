## How to run simulation in Vivado

# Creating the project
1. Open vivado gui
2. Locate Tcl Console
3. In the Tcl Console:
```
cd project_directory/src/tcl
source ./tb_create_vivado_project.tcl
```
# Running simulation
1. Select Simulation => Run Simulation from left pane
2. Once open, write to the Tcl Console
`run -all`
3. Simulation compares vhdl and verilog implementation to each other, and if any differences are found, 
it raises an assert in the end of simulation. 
Also signals `error_res_valid, error_res_valid_sticky, error_res_box, error_res_box_sticky`
indicate at which point of time errors occurred.

# Modifying simulation parameters
The generic parameters on tb_linkruncca.vhdl configure the test environment.
