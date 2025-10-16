# High-Speed 2D DCT Core for FPGA

Thiết kế và mô phỏng lõi DCT-II 2D tốc độ cao (8×8 block) trên FPGA với kiến trúc pipeline đầy đủ.

## 🎯 Đặc điểm chính

- **Thuật toán**: Loeffler 1D DCT (8-point) × 2 + transpose buffer
- **Thông lượng**: 1 sample/cycle sau khi warm-up (~64 cycles/block)
- **Độ chính xác**: Fixed-point Q1.14, sai số < 100 LSB so với floating-point
- **Giao diện**: AXI4-Stream (tvalid/tready/tdata/tlast)
- **Tài nguyên**: ~22-24 DSP, 2-4 BRAM, vài nghìn LUT/FF
- **Fmax mục tiêu**: 200+ MHz trên Artix-7/Zynq, 300+ MHz trên UltraScale

## 📁 Cấu trúc thư mục

```
.
├── rtl/                          # RTL Verilog sources
│   ├── dct1d_loeffler.v         # 1D DCT pipeline (Loeffler algorithm)
│   ├── transpose_buffer.v        # 8x8 transpose with BRAM ping-pong
│   └── dct2d_top.v              # Top-level 2D DCT with AXI4-Stream
│
├── testbench/                    # Verification
│   ├── golden_dct2d.py          # Python golden model (scipy)
│   ├── test_vectors.json        # Generated test vectors
│   ├── tb_vectors.vh            # Verilog test vector header
│   └── tb_dct2d_top.sv          # SystemVerilog testbench
│
├── hls/                          # Vitis HLS alternative
│   ├── dct2d_hls.cpp            # HLS C++ implementation
│   └── dct2d_hls_tb.cpp         # HLS testbench
│
├── scripts/                      # Build scripts
│   └── synthesize_vivado.tcl    # Vivado synthesis TCL
│
├── requirements.txt              # Python dependencies
└── README.md                     # This file
```

## 🚀 Hướng dẫn sử dụng

### 1. Tạo test vectors (Python)

```bash
cd testbench
python3 golden_dct2d.py
```

Output:
- `test_vectors.json` - Test vectors trong JSON
- `tb_vectors.vh` - Verilog header cho testbench

### 2. Simulation (ModelSim/Questa/Vivado)

**Với Vivado Simulator:**
```bash
cd sim
vivado -mode batch -source run_sim.tcl
```

**Với ModelSim:**
```bash
vlog -sv rtl/*.v testbench/*.sv
vsim -c tb_dct2d_top -do "run -all; quit"
```

**Xem waveform:**
```bash
gtkwave dct2d_tb.vcd
```

### 3. Synthesis (Vivado)

```bash
cd scripts
vivado -mode batch -source synthesize_vivado.tcl
```

Kết quả trong `build/` và `reports/`:
- Utilization report
- Timing summary
- Power analysis

**Thay đổi target FPGA:**
Sửa dòng trong `synthesize_vivado.tcl`:
```tcl
set target_part "xc7a35tcpg236-1"  # Artix-7
# set target_part "xc7z020clg484-1"  # Zynq-7020
# set target_part "xcku040-ffva1156-2-e"  # Kintex UltraScale+
```

### 4. HLS Synthesis (Vitis HLS)

```bash
cd hls
vitis_hls -f run_hls.tcl
```

Hoặc thủ công:
```bash
g++ -std=c++11 dct2d_hls_tb.cpp -o dct2d_hls_tb -lm
./dct2d_hls_tb
```

## 🔧 Tham số cấu hình

### RTL Parameters (dct2d_top.v)

```verilog
parameter INPUT_WIDTH = 8;     // Pixel width: 8-bit (0..255)
parameter OUTPUT_WIDTH = 16;   // Coefficient width: 16-bit signed
```

### Clock Constraints

Mặc định: **5ns (200 MHz)**

Để thay đổi, sửa trong `synthesize_vivado.tcl`:
```tcl
set target_clk_period 5.0  # ns
```

## 📊 Kết quả dự kiến

### Timing
- **Latency**: ~15-20 cycles (1D DCT) × 2 + transpose overhead
- **Throughput**: 64 pixels processed in ~80-100 cycles
- **Fmax**: 200-250 MHz (Artix-7), 300+ MHz (UltraScale)

### Accuracy
- **Max error**: < 100 LSB (compared to scipy.fftpack.dct)
- **RMSE**: < 10 LSB
- **Dynamic range**: ±32K (16-bit signed)

### Resource (Artix-7 xc7a35t)
```
DSP48:  22-24   (~10% of 90)
BRAM:   2-4     (transpose buffers)
LUT:    ~3000   (~5%)
FF:     ~2500   (~2.5%)
```

## 🧪 Test Coverage

Python golden model tạo 11 test patterns:

1. **DC blocks**: all 0, all 128, all 255
2. **Impulse**: single pixel at (0,0)
3. **Checkerboard**: alternating 0/255
4. **Gradients**: horizontal & vertical
5. **Diagonal**: main diagonal = 255
6. **Ramp**: linear 0..255
7. **Random**: reproducible (seed=42)

## 📐 Chi tiết thuật toán

### 2D DCT-II

```
X(u,v) = Σ Σ x(i,j) * cos(π*u*(2i+1)/16) * cos(π*v*(2j+1)/16)
         i j
```

**Separable implementation:**
1. Row DCT: `Y(i,v) = DCT1D(x(i,·))`
2. Transpose: `Y'(v,i) = Y(i,v)`
3. Column DCT: `X(u,v) = DCT1D(Y'(v,·))`

### Loeffler Algorithm (1D DCT)

- **Multiplications**: 11 (reduced from 64)
- **Additions**: 29
- **Butterfly stages**: 3
- **Pipeline depth**: 6 stages

### Fixed-Point Representation

- **Input**: 8-bit unsigned → signed (−128..127)
- **Coefficients**: Q1.14 (1 sign bit, 1 integer bit, 14 fraction bits)
- **Internal**: 16-18 bits with rounding
- **Output**: 16-bit signed with saturation

## 🛠️ Tối ưu hóa

### Để tăng Fmax:

1. **Thêm pipeline stages**: Chèn register vào đường critical
2. **Retiming**: Bật trong Vivado synthesis options
3. **DSP optimization**: Force sử dụng DSP48 cho multiply
4. **Placement constraints**: Đặt logic gần nhau

### Để giảm tài nguyên:

1. **Time-multiplexing**: Chia sẻ 1D DCT cho row và column
2. **DSP sharing**: Sử dụng sequential multiplier
3. **LUTRAM**: Dùng cho small buffers thay vì BRAM

### Để tăng throughput:

1. **Multiple DCT units**: Xử lý nhiều blocks song song
2. **Deeper pipeline**: Giảm II (Initiation Interval)
3. **Burst mode**: Xử lý nhiều frames liên tiếp

## 📚 Tài liệu tham khảo

1. **Loeffler Algorithm**: "Practical Fast 1-D DCT Algorithms with 11 Multiplications" (1989)
2. **JPEG Standard**: ISO/IEC 10918-1
3. **Xilinx XAPP**: Video Processing cores
4. **IEEE**: Fixed-Point Arithmetic

## 🐛 Debug Tips

### Simulation không khớp với golden:

1. Kiểm tra **bit width** và **scaling factor**
2. Xem **rounding mode** (truncate vs. round-to-nearest)
3. Kiểm tra **signed/unsigned** conversion
4. Đối chiếu từng stage 1D DCT

### Timing violation:

1. Xem `reports/timing_summary_synth.rpt`
2. Tìm critical path với `report_timing -max_paths 10`
3. Thêm pipeline stage hoặc giảm clock frequency
4. Kiểm tra fanout cao

### Functional error:

1. Chạy simulation với waveform: `dct2d_tb.vcd`
2. Kiểm tra control signals: `valid`, `ready`, `last`
3. Xem transpose buffer read/write timing
4. Debug từng 1D DCT độc lập

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra version tool (Vivado >= 2020.1)
2. Xem log file trong `build/` và `reports/`
3. Chạy Python golden model độc lập
4. Verify từng module riêng lẻ

## 📝 License

MIT License - Free for academic and commercial use.

## 🎓 Ứng dụng

- **Image/Video compression**: JPEG, H.264, HEVC
- **Transform coding**: signal processing
- **Feature extraction**: computer vision
- **Watermarking**: digital media
- **Frequency analysis**: spectral processing

---

**Tác giả**: hoang-01  
**Phiên bản**: 1.0  
**Ngày**: October 2025

