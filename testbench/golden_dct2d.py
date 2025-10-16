#!/usr/bin/env python3
"""
Golden DCT-II 2D Model for verification
Uses scipy.fftpack for reference DCT computation
Generates test vectors and compares with RTL output
"""

import numpy as np
from scipy.fftpack import dct
import json
import os

class GoldenDCT2D:
    """Reference 2D DCT-II implementation"""
    
    def __init__(self, block_size=8):
        self.block_size = block_size
    
    def dct1d(self, x):
        """1D DCT-II (unnormalized to match hardware)"""
        return dct(x, type=2, norm=None)
    
    def dct2d(self, block):
        """
        2D DCT-II: Apply 1D DCT on rows, then columns
        Args:
            block: 8x8 numpy array
        Returns:
            8x8 DCT coefficient array
        """
        # Row transform
        row_dct = np.zeros_like(block, dtype=np.float64)
        for i in range(self.block_size):
            row_dct[i, :] = self.dct1d(block[i, :])
        
        # Column transform
        col_dct = np.zeros_like(row_dct, dtype=np.float64)
        for j in range(self.block_size):
            col_dct[:, j] = self.dct1d(row_dct[:, j])
        
        return col_dct
    
    def quantize_to_fixed(self, value, int_bits, frac_bits, signed=True):
        """Convert float to fixed-point representation"""
        scale = 2 ** frac_bits
        quantized = np.round(value * scale)
        
        if signed:
            max_val = (2 ** (int_bits + frac_bits - 1)) - 1
            min_val = -(2 ** (int_bits + frac_bits - 1))
        else:
            max_val = (2 ** (int_bits + frac_bits)) - 1
            min_val = 0
        
        quantized = np.clip(quantized, min_val, max_val)
        return quantized.astype(np.int32)
    
    def compare_results(self, hw_result, sw_result, tolerance=100):
        """
        Compare hardware and software DCT results
        Args:
            hw_result: Hardware output (fixed-point)
            sw_result: Software golden result (fixed-point)
            tolerance: Maximum absolute difference allowed
        Returns:
            (success, max_error, mse)
        """
        diff = np.abs(hw_result - sw_result)
        max_error = np.max(diff)
        mse = np.mean(diff ** 2)
        rmse = np.sqrt(mse)
        
        success = max_error <= tolerance
        
        return success, max_error, mse, rmse

def generate_test_patterns():
    """Generate various test patterns for comprehensive testing"""
    patterns = {}
    
    # 1. DC block (constant value)
    patterns['dc_128'] = np.full((8, 8), 128, dtype=np.int32)
    patterns['dc_0'] = np.zeros((8, 8), dtype=np.int32)
    patterns['dc_255'] = np.full((8, 8), 255, dtype=np.int32)
    
    # 2. Impulse (single pixel)
    impulse = np.zeros((8, 8), dtype=np.int32)
    impulse[0, 0] = 255
    patterns['impulse'] = impulse
    
    # 3. Checkerboard
    checkerboard = np.zeros((8, 8), dtype=np.int32)
    for i in range(8):
        for j in range(8):
            checkerboard[i, j] = 255 if (i + j) % 2 == 0 else 0
    patterns['checkerboard'] = checkerboard
    
    # 4. Horizontal gradient
    patterns['gradient_h'] = np.tile(np.arange(0, 256, 32, dtype=np.int32), (8, 1))
    
    # 5. Vertical gradient
    patterns['gradient_v'] = np.tile(np.arange(0, 256, 32, dtype=np.int32).reshape(8, 1), (1, 8))
    
    # 6. Diagonal pattern
    diagonal = np.zeros((8, 8), dtype=np.int32)
    for i in range(8):
        diagonal[i, i] = 255
    patterns['diagonal'] = diagonal
    
    # 7. Ramp
    patterns['ramp'] = np.arange(64, dtype=np.int32).reshape(8, 8) * 4
    
    # 8. Random (reproducible)
    np.random.seed(42)
    patterns['random_1'] = np.random.randint(0, 256, (8, 8), dtype=np.int32)
    patterns['random_2'] = np.random.randint(0, 256, (8, 8), dtype=np.int32)
    
    # 9. Edge test (all boundaries)
    patterns['all_zeros'] = np.zeros((8, 8), dtype=np.int32)
    patterns['all_max'] = np.full((8, 8), 255, dtype=np.int32)
    
    return patterns

def generate_verilog_testbench(patterns, golden_results, filename='tb_vectors.vh'):
    """Generate Verilog header file with test vectors"""
    with open(filename, 'w') as f:
        f.write("// Auto-generated test vectors for DCT 2D\n")
        f.write("// Format: input pixels (8-bit) and expected DCT coefficients (16-bit)\n\n")
        
        for idx, (name, pattern) in enumerate(patterns.items()):
            f.write(f"// Test pattern {idx}: {name}\n")
            
            # Input pixels (row-major)
            f.write(f"localparam [0:63][7:0] test_input_{idx} = '{{\n")
            pixels = pattern.flatten()
            for i in range(0, 64, 8):
                line = ", ".join([f"8'd{p}" for p in pixels[i:i+8]])
                f.write(f"    {line}{',' if i < 56 else ''}\n")
            f.write("};\n\n")
            
            # Expected output (DCT coefficients)
            f.write(f"localparam [0:63][15:0] test_output_{idx} = '{{\n")
            coeffs = golden_results[name].flatten()
            for i in range(0, 64, 8):
                line = ", ".join([f"16'sd{int(c)}" for c in coeffs[i:i+8]])
                f.write(f"    {line}{',' if i < 56 else ''}\n")
            f.write("};\n\n")
        
        f.write(f"localparam NUM_TESTS = {len(patterns)};\n")

def save_test_vectors_json(patterns, golden_results, filename='test_vectors.json'):
    """Save test vectors in JSON format for Python testbench"""
    data = {
        'test_cases': []
    }
    
    for name, pattern in patterns.items():
        test_case = {
            'name': name,
            'input': pattern.tolist(),
            'expected_output': golden_results[name].tolist()
        }
        data['test_cases'].append(test_case)
    
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)

def main():
    """Main test generation and verification"""
    print("=" * 70)
    print("DCT 2D Golden Model and Test Vector Generator")
    print("=" * 70)
    
    dct = GoldenDCT2D()
    
    # Generate test patterns
    print("\nGenerating test patterns...")
    patterns = generate_test_patterns()
    print(f"Generated {len(patterns)} test patterns")
    
    # Compute golden DCT results
    print("\nComputing golden DCT results...")
    golden_results = {}
    
    for name, pattern in patterns.items():
        # Convert to signed (center around 0 for better DCT properties)
        pattern_signed = pattern.astype(np.float64) - 128.0
        
        # Compute 2D DCT
        dct_result = dct.dct2d(pattern_signed)
        
        # Scale to fixed-point (match hardware scaling)
        # Hardware uses Q1.14 coefficients, results are scaled by 8*8=64
        # We keep integer representation for comparison
        dct_result_fixed = np.round(dct_result).astype(np.int32)
        
        golden_results[name] = dct_result_fixed
        
        print(f"  {name:20s}: DC={dct_result_fixed[0,0]:8d}, "
              f"range=[{np.min(dct_result_fixed):7d}, {np.max(dct_result_fixed):7d}]")
    
    # Create output directory
    os.makedirs('../testbench', exist_ok=True)
    
    # Generate Verilog testbench vectors
    print("\nGenerating Verilog test vectors...")
    generate_verilog_testbench(patterns, golden_results, 
                               '../testbench/tb_vectors.vh')
    print("  Saved to: testbench/tb_vectors.vh")
    
    # Save JSON test vectors
    print("\nGenerating JSON test vectors...")
    save_test_vectors_json(patterns, golden_results,
                          '../testbench/test_vectors.json')
    print("  Saved to: testbench/test_vectors.json")
    
    # Display sample results
    print("\n" + "=" * 70)
    print("Sample DCT Results (DC block pattern):")
    print("=" * 70)
    print("\nInput (8x8 DC=128):")
    print(patterns['dc_128'])
    print("\nDCT Output:")
    print(golden_results['dc_128'])
    
    print("\n" + "=" * 70)
    print("Sample DCT Results (Checkerboard pattern):")
    print("=" * 70)
    print("\nInput (8x8):")
    print(patterns['checkerboard'])
    print("\nDCT Output:")
    print(golden_results['checkerboard'])
    
    # Verification example
    print("\n" + "=" * 70)
    print("Verification Example:")
    print("=" * 70)
    print("To verify hardware output, use:")
    print("  success, max_err, mse, rmse = dct.compare_results(hw_out, golden)")
    print("  Typical tolerance: 100 (for 16-bit fixed-point)")
    print("\nExpected accuracy:")
    print("  - Max error: < 100 LSB (0.6% for 16-bit range)")
    print("  - RMSE: < 10 LSB")
    
    print("\n" + "=" * 70)
    print("Test vector generation complete!")
    print("=" * 70)

if __name__ == '__main__':
    main()

