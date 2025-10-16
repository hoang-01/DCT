################################################################################
# Vivado Simulation Script for DCT 2D Testbench
################################################################################

set project_name "dct2d_sim"
set top_tb "tb_dct2d_top"
set sim_dir "./sim_build"

# Create simulation project
create_project $project_name $sim_dir -part xc7a35tcpg236-1 -force

# Add RTL sources
add_files [glob ../rtl/*.v]

# Add testbench
add_files -fileset sim_1 [glob ../testbench/*.sv]
add_files -fileset sim_1 [glob ../testbench/*.vh]

# Set testbench as top
set_property top $top_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Simulation settings
set_property -name {xsim.simulate.runtime} -value {1ms} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

puts "Starting simulation..."
launch_simulation

# Run simulation
run 1ms

puts "Simulation complete!"
close_sim

