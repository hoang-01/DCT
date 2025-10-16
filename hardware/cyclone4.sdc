# ============================================================================
# Synopsys Design Constraints (SDC) for Cyclone IV DCT Demo
# ============================================================================

# Clock constraints
create_clock -name {clk_50mhz} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50mhz}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects
derive_clock_uncertainty

# Set input delay for switches and buttons (asynchronous inputs)
set_input_delay -clock clk_50mhz -max 2.0 [get_ports {sw[*]}]
set_input_delay -clock clk_50mhz -max 2.0 [get_ports {key[*]}]
set_input_delay -clock clk_50mhz -max 2.0 [get_ports {rst_n}]

# Set output delay for 7-segment and LEDs
set_output_delay -clock clk_50mhz -max 2.0 [get_ports {hex0[*]}]
set_output_delay -clock clk_50mhz -max 2.0 [get_ports {hex1[*]}]
set_output_delay -clock clk_50mhz -max 2.0 [get_ports {hex2[*]}]
set_output_delay -clock clk_50mhz -max 2.0 [get_ports {hex3[*]}]
set_output_delay -clock clk_50mhz -max 2.0 [get_ports {led[*]}]

# Set false paths for asynchronous inputs (debouncing handled in design)
set_false_path -from [get_ports {key[*]}] -to [all_registers]
set_false_path -from [get_ports {sw[*]}] -to [all_registers]

