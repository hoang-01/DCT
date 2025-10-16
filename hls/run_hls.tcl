################################################################################
# Vitis HLS Script for DCT 2D
################################################################################

# Project settings
open_project dct2d_hls_project -reset
set_top dct2d_top

# Add files
add_files dct2d_hls.cpp
add_files -tb dct2d_hls_tb.cpp

# Solution settings
open_solution "solution1" -reset

# Target device
set_part {xc7z020clg484-1}
create_clock -period 5 -name default

# Directives
config_compile -pipeline_loops 0
config_rtl -reset_level low

# C Simulation
puts "Running C Simulation..."
csim_design

# Synthesis
puts "Running HLS Synthesis..."
csynth_design

# Co-simulation (optional)
# cosim_design

# Export RTL
puts "Exporting RTL..."
export_design -format ip_catalog

puts "HLS flow complete!"
close_project

