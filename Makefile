################################################################################
# Makefile for DCT 2D FPGA Project
################################################################################

.PHONY: help test vectors sim synth hls clean

help:
	@echo "=================================="
	@echo "DCT 2D FPGA Project Makefile"
	@echo "=================================="
	@echo "Available targets:"
	@echo "  vectors    - Generate test vectors with Python"
	@echo "  sim        - Run Vivado simulation"
	@echo "  synth      - Run Vivado synthesis"
	@echo "  hls        - Run Vitis HLS flow"
	@echo "  test       - Generate vectors and run simulation"
	@echo "  clean      - Clean all build outputs"
	@echo "=================================="

# Generate test vectors
vectors:
	@echo "Generating test vectors..."
	cd testbench && python3 golden_dct2d.py
	@echo "Done!"

# Run simulation (Vivado)
sim: vectors
	@echo "Running Vivado simulation..."
	cd scripts && vivado -mode batch -source run_sim_vivado.tcl

# Run synthesis
synth:
	@echo "Running Vivado synthesis..."
	cd scripts && vivado -mode batch -source synthesize_vivado.tcl

# Run HLS flow
hls:
	@echo "Running Vitis HLS..."
	cd hls && vitis_hls -f run_hls.tcl

# Full test flow
test: vectors
	@echo "Running full test flow..."
	@echo "1. Python golden model verification..."
	cd testbench && python3 golden_dct2d.py
	@echo "2. RTL simulation..."
	cd scripts && vivado -mode batch -source run_sim_vivado.tcl
	@echo "Test complete!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf reports/
	rm -rf sim_build/
	rm -rf hls/dct2d_hls_project/
	rm -rf scripts/.Xil/
	rm -rf testbench/test_vectors.json
	rm -rf testbench/tb_vectors.vh
	rm -f *.log *.jou *.pb *.wdb
	rm -f testbench/*.vcd
	@echo "Clean complete!"

