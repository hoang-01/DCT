#!/usr/bin/env python3
"""
Quick demo of DCT 2D computation
Shows input, DCT output, and inverse DCT
"""

import numpy as np
from scipy.fftpack import dct, idct
import json

def dct2d(block):
    """2D DCT-II"""
    # Row DCT
    row_dct = np.zeros_like(block, dtype=np.float64)
    for i in range(8):
        row_dct[i, :] = dct(block[i, :], type=2, norm=None)
    
    # Column DCT
    col_dct = np.zeros_like(row_dct, dtype=np.float64)
    for j in range(8):
        col_dct[:, j] = dct(row_dct[:, j], type=2, norm=None)
    
    return col_dct

def idct2d(coeffs):
    """2D Inverse DCT-II"""
    # Column IDCT
    col_idct = np.zeros_like(coeffs, dtype=np.float64)
    for j in range(8):
        col_idct[:, j] = idct(coeffs[:, j], type=2, norm=None)
    
    # Row IDCT
    row_idct = np.zeros_like(col_idct, dtype=np.float64)
    for i in range(8):
        row_idct[i, :] = idct(col_idct[i, :], type=2, norm=None)
    
    return row_idct / 64.0  # Scale factor

print("=" * 70)
print("DCT 2D Quick Demo")
print("=" * 70)

# Test 1: Simple gradient
print("\n--- Test 1: Horizontal Gradient ---")
gradient = np.tile(np.arange(0, 256, 32, dtype=np.float64), (8, 1))
print("\nInput (8x8):")
print(gradient.astype(int))

gradient_centered = gradient - 128.0
dct_result = dct2d(gradient_centered)
print("\nDCT Coefficients (showing top-left 4x4):")
print(dct_result[:4, :4].astype(int))

reconstructed = idct2d(dct_result) + 128.0
error = np.max(np.abs(gradient - reconstructed))
print(f"\nReconstruction error: {error:.6f} (should be ~0)")

# Test 2: Checkerboard
print("\n" + "=" * 70)
print("--- Test 2: Checkerboard Pattern ---")
checker = np.zeros((8, 8), dtype=np.float64)
for i in range(8):
    for j in range(8):
        checker[i, j] = 255 if (i + j) % 2 == 0 else 0
print("\nInput (8x8):")
print(checker.astype(int))

checker_centered = checker - 128.0
dct_checker = dct2d(checker_centered)
print("\nDCT Coefficients (showing top-left 4x4):")
print(dct_checker[:4, :4].astype(int))
print(f"\nDC coefficient: {dct_checker[0,0]:.0f}")
print(f"Max AC coefficient: {np.max(np.abs(dct_checker[1:,:])):.0f}")

# Test 3: Random image block
print("\n" + "=" * 70)
print("--- Test 3: Random Block (simulating real image) ---")
np.random.seed(42)
random_block = np.random.randint(50, 200, (8, 8)).astype(np.float64)
print("\nInput (8x8):")
print(random_block.astype(int))

random_centered = random_block - 128.0
dct_random = dct2d(random_centered)
print("\nDCT Coefficients (showing top-left 4x4):")
print(dct_random[:4, :4].astype(int))

# Simulate quantization (like JPEG)
quant_matrix = np.array([
    [16, 11, 10, 16, 24, 40, 51, 61],
    [12, 12, 14, 19, 26, 58, 60, 55],
    [14, 13, 16, 24, 40, 57, 69, 56],
    [14, 17, 22, 29, 51, 87, 80, 62],
    [18, 22, 37, 56, 68, 109, 103, 77],
    [24, 35, 55, 64, 81, 104, 113, 92],
    [49, 64, 78, 87, 103, 121, 120, 101],
    [72, 92, 95, 98, 112, 100, 103, 99]
])

dct_quantized = np.round(dct_random / quant_matrix) * quant_matrix
reconstructed_lossy = idct2d(dct_quantized) + 128.0
reconstructed_lossy = np.clip(reconstructed_lossy, 0, 255)

print("\nAfter JPEG-like quantization:")
print(reconstructed_lossy.astype(int))
print(f"Average error: {np.mean(np.abs(random_block - reconstructed_lossy)):.2f}")
print(f"Max error: {np.max(np.abs(random_block - reconstructed_lossy)):.0f}")

# Energy compaction
print("\n" + "=" * 70)
print("--- DCT Energy Compaction Demo ---")
energy = np.abs(dct_random) ** 2
total_energy = np.sum(energy)
dc_energy = energy[0, 0]
top_left_4x4_energy = np.sum(energy[:4, :4])

print(f"DC energy: {100*dc_energy/total_energy:.1f}%")
print(f"Top-left 4x4 energy: {100*top_left_4x4_energy/total_energy:.1f}%")
print("(Most energy concentrated in low frequencies - basis of compression)")

print("\n" + "=" * 70)
print("Demo complete!")
print("=" * 70)
print("\nKey takeaways:")
print("1. DCT transforms spatial domain to frequency domain")
print("2. Most energy concentrated in low frequencies (top-left)")
print("3. High frequencies (bottom-right) can be quantized heavily")
print("4. This is the foundation of JPEG/video compression")
print("\nYour FPGA implementation does this at 200+ MHz!")

