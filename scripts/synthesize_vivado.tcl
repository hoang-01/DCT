################################################################################
# Vivado Synthesis Script for DCT 2D High-Speed Core
# Target: Xilinx Artix-7 / Zynq-7000 / UltraScale
# Author: Bé Tiến Đạt Xinh Gái
################################################################################

# Configuration
set project_name "dct2d_fpga"
set top_module "dct2d_top"
set target_part "xc7a35tcpg236-1"  ;# Artix-7 35T (change as needed)
# Alternative parts:
# xc7z020clg484-1  - Zynq-7020
# xcku040-ffva1156-2-e - Kintex UltraScale+

set target_clk_period 5.0  ;# 200 MHz
set rtl_dir "../rtl"
set output_dir "./build"
set reports_dir "./reports"

# Create project directories
file mkdir $output_dir
file mkdir $reports_dir

# Create project
create_project $project_name $output_dir -part $target_part -force

# Add RTL sources
add_files [glob $rtl_dir/*.v]
set_property top $top_module [current_fileset]

# Set Verilog 2001 standard
set_property file_type {Verilog} [get_files *.v]

# Create clock constraint
create_clock -period $target_clk_period -name clk [get_ports clk]
set_input_delay -clock clk [expr $target_clk_period * 0.2] [all_inputs]
set_output_delay -clock clk [expr $target_clk_period * 0.2] [all_outputs]

# Synthesis settings for high performance
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC false [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 [get_runs synth_1]

puts "================================================================================"
puts "Starting Synthesis..."
puts "Target: $target_part"
puts "Clock: [expr 1000.0 / $target_clk_period] MHz"
puts "================================================================================"

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "\n================================================================================"
puts "Synthesis completed successfully"
puts "================================================================================"

# Open synthesized design
open_run synth_1

# Generate utilization report
report_utilization -file $reports_dir/utilization_synth.rpt
report_utilization -hierarchical -file $reports_dir/utilization_hierarchical.rpt

# Generate timing report
report_timing_summary -file $reports_dir/timing_summary_synth.rpt
report_timing -sort_by slack -max_paths 10 -file $reports_dir/timing_worst_paths.rpt

# Generate power report
report_power -file $reports_dir/power_synth.rpt

# Display key metrics
puts "\n================================================================================"
puts "Resource Utilization Summary:"
puts "================================================================================"

set util_rpt [report_utilization -return_string]
puts $util_rpt

puts "\n================================================================================"
puts "Timing Summary:"
puts "================================================================================"

set timing_rpt [report_timing_summary -return_string]
puts $timing_rpt

# Check if timing is met
set wns [get_property SLACK [get_timing_paths]]
if {$wns < 0} {
    puts "\nWARNING: Negative slack detected! WNS = $wns ns"
    puts "Consider:"
    puts "  1. Increasing clock period"
    puts "  2. Adding more pipeline stages"
    puts "  3. Optimizing critical paths"
} else {
    puts "\nTiming PASSED! WNS = $wns ns"
    puts "Maximum achievable frequency: [expr 1000.0 / ($target_clk_period - $wns)] MHz"
}

# Implementation (optional - uncomment to run)
# puts "\n================================================================================"
# puts "Starting Implementation..."
# puts "================================================================================"
# 
# set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap [get_runs impl_1]
# set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraPostPlacementOpt [get_runs impl_1]
# set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
# 
# launch_runs impl_1 -jobs 4
# wait_on_run impl_1
# 
# open_run impl_1
# 
# report_utilization -file $reports_dir/utilization_impl.rpt
# report_timing_summary -file $reports_dir/timing_summary_impl.rpt
# report_power -file $reports_dir/power_impl.rpt
# 
# # Generate bitstream (if needed)
# # write_bitstream -force $output_dir/$project_name.bit

puts "\n================================================================================"
puts "All done! Check reports in: $reports_dir"
puts "================================================================================"

# Save project and close
save_project_as $project_name $output_dir -force
# close_project

