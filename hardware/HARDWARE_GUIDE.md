# 🎯 DCT 2D trên Cyclone IV FPGA - Hướng dẫn Hardware

## 📋 Board của bạn: Cyclone IV Development Kit

### Thông số kỹ thuật
- **FPGA**: Cyclone IV EP4CE6E22C8
  - Logic Elements: 6,272
  - M9K Memory: 276 Kbits
  - Multipliers: 30 (18×18)
  - Max I/O: 92
- **Clock**: 50 MHz onboard oscillator
- **Display**: 4× 7-segment displays (HEX0-HEX3)
- **Input**: 4× DIP switches, 4× push buttons
- **Output**: 8× LEDs
- **Programming**: USB Blaster

---

## 🎮 Cách sử dụng Demo

### Chức năng các nút điều khiển

#### **DIP Switches (SW[3:0])**
- **SW[1:0]**: Chọn test pattern
  ```
  00 = DC pattern (tất cả = 128)
  01 = Checkerboard (cờ vua)
  10 = Horizontal gradient
  11 = Impulse (1 pixel sáng)
  ```
- **SW[3:2]**: Chọn DCT coefficient để hiển thị
  ```
  00 = Coefficient 0 (DC component)
  01 = Coefficient 2
  10 = Coefficient 4
  11 = Coefficient 6
  ```

#### **Push Buttons (KEY[3:0], active low)**
- **KEY[0]**: Bắt đầu tính toán DCT (nhấn để trigger)
- **KEY[1]**: Quay về chế độ IDLE
- **KEY[2]**: (Reserved)
- **KEY[3]**: (Reserved)

#### **7-Segment Displays (HEX3-HEX0)**
Hiển thị giá trị DCT coefficient dạng hexadecimal (16-bit signed)
```
HEX3 HEX2 HEX1 HEX0
  F    F    F    F    = -1 (0xFFFF)
  0    0    0    0    = 0
  7    F    F    F    = 32767 (max positive)
```

#### **LEDs (LED[7:0])**
Hiển thị trạng thái:
```
LED[0] = 1: IDLE (sẵn sàng)
LED[1] = 1: LOAD (đang nạp dữ liệu)
LED[2] = 1: COMPUTE (đang tính toán)
LED[3] = 1: DISPLAY (đang hiển thị kết quả)
LED[7:4]: (Reserved cho mở rộng)
```

---

## 🔧 Cài đặt Quartus II

### Bước 1: Download Quartus II
1. Truy cập: https://www.intel.com/content/www/us/en/software-kit/785086
2. Download **Quartus Prime Lite Edition** (miễn phí)
3. Chọn version hỗ trợ Cyclone IV (13.0sp1 hoặc mới hơn)
4. Install kèm **ModelSim** (cho simulation)

### Bước 2: Install USB Blaster Driver
1. Cắm board vào USB
2. Windows sẽ tìm driver
3. Nếu không tự động:
   - Vào Device Manager
   - Tìm "Unknown Device"
   - Update driver → Browse → Chọn `<Quartus>/drivers/usb-blaster`

---

## 🚀 Biên dịch và nạp FPGA

### Bước 1: Tạo project Quartus

```bash
# 1. Mở Quartus II
# 2. File → New Project Wizard

Project Name: dct2d_cyclone4
Top-Level Entity: cyclone4_top
Device: EP4CE6E22C8 (Cyclone IV E)

# 3. Add files:
#    - cyclone4_top.v
#    - cyclone4.qsf (pin assignments)
#    - cyclone4.sdc (timing constraints)
```

**HOẶC dùng command line:**
```bash
cd hardware
quartus_sh --flow compile dct2d_cyclone4
```

### Bước 2: Compile Design

#### Trong Quartus GUI:
1. **Processing → Start Compilation** (Ctrl+L)
2. Đợi ~2-5 phút
3. Kiểm tra:
   - ✅ Compilation successful
   - ⚠️ Nếu có lỗi, xem phần Troubleshooting

#### Xem báo cáo:
- **Fitter Report**: Utilization, timing
- **TimeQuest Timing Analyzer**: Timing slack
- **Resource Usage**:
  ```
  Logic Elements: ~800 / 6,272 (13%)
  Registers: ~200 / 6,272 (3%)
  M9K Memory: 0 / 30 (0%)
  Multipliers: 8 / 30 (27%)
  ```

### Bước 3: Programming FPGA

#### Chuẩn bị:
1. Cắm board vào USB
2. Mở **Quartus Programmer**
3. Hardware Setup → USB-Blaster

#### Nạp bitstream:
```
1. Add File → output_files/cyclone4_top.sof
2. Check "Program/Configure"
3. Click "Start"
```

**Hoặc command line:**
```bash
quartus_pgm -c USB-Blaster -m JTAG -o "p;output_files/cyclone4_top.sof"
```

---

## 🧪 Test và Verification

### Test Case 1: DC Pattern
```
1. Đặt SW[1:0] = 00 (DC pattern)
2. Đặt SW[3:2] = 00 (hiển thị DC coefficient)
3. Nhấn KEY[0] để tính toán
4. Quan sát:
   - LED[1] sáng (LOAD)
   - LED[2] sáng (COMPUTE)
   - LED[3] sáng (DISPLAY)
   - 7-segment hiển thị: 0000 (DC = 0 cho pattern 128)
```

### Test Case 2: Checkerboard
```
1. Đặt SW[1:0] = 01 (Checkerboard)
2. Đặt SW[3:2] = 00 (DC coefficient)
3. Nhấn KEY[0]
4. Kết quả mong đợi:
   - DC coefficient ~ FF80 (âm, khoảng -128)
```

### Test Case 3: Impulse
```
1. Đặt SW[1:0] = 11 (Impulse)
2. Đặt SW[3:2] = 00
3. Nhấn KEY[0]
4. Kết quả:
   - DC coefficient ~ 807F (dương lớn, ~32767)
```

### Quan sát các coefficient khác
```
1. Sau khi tính toán xong (LED[3] = 1)
2. Thay đổi SW[3:2] để xem các coefficient khác:
   - 00 → Coef 0 (DC)
   - 01 → Coef 2
   - 10 → Coef 4
   - 11 → Coef 6
```

---

## 📊 Hiểu kết quả

### Giá trị 7-segment (Hex)

7-segment hiển thị số signed 16-bit ở dạng **hexadecimal**:

| Display | Decimal | Ý nghĩa |
|---------|---------|---------|
| `0000` | 0 | Không có tần số này |
| `00FF` | 255 | Tần số nhỏ, dương |
| `7FFF` | 32767 | Tần số rất cao, dương |
| `8000` | -32768 | Tần số rất cao, âm |
| `FF00` | -256 | Tần số nhỏ, âm |

### Chuyển đổi Hex → Decimal

**Số dương** (bit cao = 0):
```
HEX: 01F4 → DEC: 1×4096 + 15×256 + 4 = 500
```

**Số âm** (bit cao = 1):
```
HEX: FF80 → Two's complement
     = -(0x10000 - 0xFF80)
     = -(65536 - 65408)
     = -128
```

**Tool nhanh:**
```python
# Chuyển đổi trong Python
hex_val = 0xFF80
if hex_val >= 0x8000:
    dec_val = hex_val - 0x10000  # Âm
else:
    dec_val = hex_val  # Dương
print(dec_val)  # Output: -128
```

---

## 🐛 Troubleshooting

### Lỗi biên dịch

#### "Error: Can't place logic"
```
Nguyên nhân: Thiết kế quá lớn cho FPGA
Giải pháp:
  1. Giảm số pipeline stages
  2. Dùng time-sharing thay vì parallel
  3. Nâng cấp lên Cyclone IV E22C8 (bigger)
```

#### "Error: Timing requirements not met"
```
Nguyên nhân: Clock 50MHz quá nhanh cho thiết kế
Giải pháp:
  1. Thêm pipeline registers
  2. Giảm clock xuống 25 MHz (chia 2)
  3. Optimize critical paths
```

### Lỗi programming

#### "No hardware detected"
```
Giải pháp:
  1. Kiểm tra cáp USB
  2. Install lại USB Blaster driver
  3. Thử port USB khác
  4. Restart Quartus Programmer
```

#### "Device not found"
```
Giải pháp:
  1. Kiểm tra nguồn board (switch ON)
  2. Auto Detect trong Programmer
  3. Chọn đúng JTAG chain
```

### Lỗi chức năng

#### 7-segment không hiển thị
```
Kiểm tra:
  1. Pin assignments trong .qsf
  2. Common anode vs common cathode
  3. Logic level (active high/low)
```

#### Kết quả sai
```
Debug:
  1. Simulation trong ModelSim trước
  2. Kiểm tra signed/unsigned
  3. Verify cosine table values
  4. Check scaling factors
```

---

## 🔬 ModelSim Simulation (Optional)

### Chạy simulation trước khi nạp FPGA

```bash
# 1. Compile design
vlog cyclone4_top.v

# 2. Tạo testbench (hoặc dùng GUI)
vsim -gui work.cyclone4_top

# 3. Add waves
add wave -radix hex *

# 4. Kích thích inputs
force clk_50mhz 0 0, 1 10ns -r 20ns
force rst_n 0 0, 1 50ns
force sw 4'b0001 100ns
force key 4'b1110 500ns, 4'b1111 1000ns

# 5. Run
run 10us
```

---

## 📈 Mở rộng

### Nâng cấp dễ dàng

1. **Hiển thị nhiều coefficients**
   - Scan qua tất cả 8 coefficients tự động
   - Dùng timer để rotate display

2. **Thêm test patterns**
   - Sửa ROM trong `cyclone4_top.v`
   - Thêm switch options

3. **Full 2D DCT**
   - Tích hợp `dct2d_top.v` gốc
   - Cần board lớn hơn (Cyclone IV E22 hoặc Cyclone V)

4. **UART output**
   - Gửi coefficients qua RS232
   - Visualize trên PC

5. **VGA display**
   - Hiển thị ảnh 8×8 và DCT
   - Cần VGA module thêm

---

## 📝 Quick Reference

### Pin Mapping Summary
```
Clock:     PIN_23  (50 MHz)
Reset:     PIN_25  (active low button)
Switches:  PIN_88-91 (SW[3:0])
Buttons:   PIN_24, 64-66 (KEY[3:0])
LEDs:      PIN_76-87 (LED[7:0])
7-seg:     See .qsf file for details
```

### Typical Workflow
```
1. Modify cyclone4_top.v
2. Save
3. Compile (Ctrl+L)
4. Program FPGA
5. Test on board
6. Iterate
```

### Resource Links
- Cyclone IV Handbook: https://www.intel.com/cyclone-iv
- Quartus Docs: https://www.intel.com/quartus
- USB Blaster: https://www.intel.com/usb-blaster

---

## ✅ Checklist Deployment

- [ ] Quartus II installed
- [ ] USB Blaster driver working
- [ ] Project created
- [ ] Files added (`.v`, `.qsf`, `.sdc`)
- [ ] Compilation successful
- [ ] No timing violations
- [ ] Board connected
- [ ] Programming successful
- [ ] LEDs lighting up
- [ ] 7-segment showing values
- [ ] Tests passing

---

**Chúc bạn thành công nạp lên FPGA! 🎉**

Nếu gặp vấn đề, đọc phần Troubleshooting hoặc kiểm tra compilation reports trong Quartus!

