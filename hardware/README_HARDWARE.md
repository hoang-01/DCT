# 🎮 DCT 2D Demo trên Cyclone IV FPGA

## 🎯 Tóm tắt nhanh

Đây là phiên bản **đơn giản hóa** của DCT 2D core để chạy trên **Cyclone IV FPGA board** của bạn. 

### Khác biệt so với full design:

| Feature | Full Design (Xilinx) | Cyclone IV Demo |
|---------|---------------------|-----------------|
| **Algorithm** | 2D DCT (Row + Column) | 1D DCT only (row) |
| **Resource** | 22 DSP, 2-4 BRAM | 8 multipliers, 0 BRAM |
| **Interface** | AXI4-Stream | Simple I/O |
| **Input** | 64 pixels streaming | Pre-loaded patterns |
| **Output** | 64 coefficients | Display 1 coefficient |
| **Display** | External system | 7-segment onboard |

### Tại sao đơn giản hóa?

Cyclone IV **EP4CE6** có tài nguyên hạn chế:
- ✅ Logic Elements: 6,272 (đủ cho demo)
- ❌ Memory: chỉ 276 Kbits (không đủ cho full 2D)
- ✅ Multipliers: 30 (đủ cho 1D DCT)

---

## 📁 Files cho Hardware

```
hardware/
├── cyclone4_top.v           # Top module cho Cyclone IV
│                             # - Simplified 1D DCT
│                             # - 7-segment display driver
│                             # - Button/switch interface
│
├── cyclone4.qsf             # Pin assignments (Quartus)
│                             # - Clock, reset, switches
│                             # - 7-segment, LEDs
│                             # - USB Blaster settings
│
├── cyclone4.sdc             # Timing constraints
│                             # - 50 MHz clock
│                             # - I/O delays
│
├── HARDWARE_GUIDE.md        # Hướng dẫn chi tiết
│                             # - Cài Quartus
│                             # - Compile & program
│                             # - Testing procedures
│
└── README_HARDWARE.md       # File này
```

---

## 🚀 Quick Start (5 phút)

### 1. Cài đặt Quartus II

```
Download: Intel Quartus Prime Lite (FREE)
Link: https://www.intel.com/quartus
Version: 13.0 hoặc mới hơn
Size: ~5 GB
```

### 2. Tạo project

```bash
# Trong Quartus:
File → New Project Wizard
  Project: dct2d_cyclone4
  Device: EP4CE6E22C8
  Files: Add cyclone4_top.v, cyclone4.qsf, cyclone4.sdc
```

### 3. Compile

```bash
Processing → Start Compilation (Ctrl+L)
# Hoặc command line:
quartus_sh --flow compile dct2d_cyclone4
```

### 4. Program

```bash
Tools → Programmer
  Hardware: USB-Blaster
  File: cyclone4_top.sof
  ✓ Program/Configure
  → Start
```

### 5. Test!

```
1. Đặt SW[1:0] = 01 (checkerboard pattern)
2. Nhấn KEY[0] (compute)
3. Xem 7-segment displays hiển thị DCT coefficient
4. LED[3] sáng = hoàn thành!
```

---

## 🎮 Sử dụng Demo

### Inputs

**DIP Switches:**
- `SW[1:0]`: Chọn pattern (00=DC, 01=checker, 10=gradient, 11=impulse)
- `SW[3:2]`: Chọn coefficient hiển thị (0, 2, 4, hoặc 6)

**Push Buttons:**
- `KEY[0]`: Bắt đầu tính DCT
- `KEY[1]`: Reset về IDLE

### Outputs

**7-Segment:** Hiển thị giá trị DCT coefficient (hex, 16-bit signed)

**LEDs:** Trạng thái
- `LED[0]`: IDLE
- `LED[1]`: LOADING
- `LED[2]`: COMPUTING  
- `LED[3]`: DISPLAY

---

## 📊 Kết quả mong đợi

### Test Pattern: Checkerboard
```
Input:  Cờ vua 8×8 (alternating 0/255)
Output: DC coefficient ~ FF80 (-128 in hex)
        AC coefficients: High values (high frequency)
```

### Test Pattern: DC (all 128)
```
Input:  Tất cả pixels = 128
Output: All coefficients = 0000 (no frequency content)
```

### Test Pattern: Impulse
```
Input:  Chỉ 1 pixel = 255, còn lại = 0
Output: DC coefficient ~ 7F00 (positive large)
```

---

## 🔧 Customization

### Thay đổi test patterns

Edit `cyclone4_top.v`:
```verilog
// Line ~60
2'b00: begin  // Your custom pattern
    for (i = 0; i < 64; i = i + 1)
        test_pattern[i] = // Your values here
end
```

### Thêm coefficients

Để hiển thị tất cả 8 coefficients, thêm counter:
```verilog
reg [2:0] coef_display_idx;
// Increment every 1 second to scan through
```

### Port sang board khác

Chỉnh sửa `.qsf`:
1. Đổi device name
2. Update pin numbers theo schematic board mới
3. Adjust clock frequency

---

## ⚠️ Limitations

1. **Chỉ 1D DCT**: Demo này chỉ tính DCT cho 1 hàng (8 pixels)
   - Full 2D cần: 2× DCT + transpose buffer
   - Cần board lớn hơn (Cyclone IV E22 hoặc Cyclone V)

2. **Pre-loaded patterns**: Không có input streaming
   - Patterns hard-coded trong ROM
   - Để streaming cần thêm UART/VGA interface

3. **Limited display**: Chỉ hiển thị 1 coefficient
   - 7-segment không đủ cho 64 coefficients
   - Dùng UART hoặc VGA cho full output

---

## 🚀 Nâng cấp lên Full 2D

Nếu bạn muốn full 2D DCT:

### Option 1: Board lớn hơn
```
Cyclone IV E22: 22,320 LE (gấp 3.5×)
Cyclone V:      ~50,000 LE
DE10-Lite:      Có SDRAM, VGA
```

### Option 2: Optimize design
```
- Time-multiplex: dùng chung 1 DCT cho row/col
- External memory: SRAM/SDRAM cho transpose
- Reduce precision: 8-bit coefficients
```

### Option 3: Kết hợp với soft processor
```
- Nios II processor: điều khiển
- DCT core: accelerator
- Memory: shared SDRAM
```

---

## 📚 Đọc thêm

- **HARDWARE_GUIDE.md**: Hướng dẫn chi tiết từng bước
- **cyclone4_top.v**: Code có comment đầy đủ
- **../README.md**: Full design documentation

---

## ✅ Checklist

Trước khi bắt đầu:
- [ ] Có board Cyclone IV
- [ ] Có cáp USB (cho USB Blaster)
- [ ] Download Quartus II
- [ ] Install USB Blaster driver

Deployment:
- [ ] Project created
- [ ] Files added
- [ ] Compilation OK (no errors)
- [ ] Timing met (no violations)
- [ ] Programming successful
- [ ] Board responding

Testing:
- [ ] LEDs working
- [ ] 7-segment displaying
- [ ] Switches controlling pattern
- [ ] Button triggering compute
- [ ] Results matching expectations

---

## 🆘 Help

**Lỗi compile?** → Xem HARDWARE_GUIDE.md phần Troubleshooting

**Không program được?** → Kiểm tra USB Blaster driver

**Kết quả sai?** → Verify với Python golden model

**Muốn full 2D?** → Cần board lớn hơn hoặc optimize

---

**Good luck với FPGA của bạn! 🎉**

