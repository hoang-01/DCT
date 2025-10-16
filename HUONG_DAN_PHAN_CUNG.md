# 🔧 HƯỚNG DẪN PHẦN CỨNG - Nạp Code vào Board Cyclone IV

## 📋 TÓM TẮT NHANH

**Board của bạn:** Cyclone IV EP4CE6E22C8  
**Cách nạp:** Qua USB với Quartus Programmer  
**Thời gian:** ~20 phút (lần đầu), ~5 phút (lần sau)

---

## 🎯 CÁC BƯỚC CHÍNH

```
1. Cài Quartus II (30 phút) → Phần mềm lập trình FPGA
2. Tạo Project (5 phút)      → Load code vào Quartus
3. Compile (3 phút)          → Biên dịch code thành bitstream
4. Nạp vào Board (2 phút)    → Programming qua USB
5. Test (2 phút)             → Chạy thử và xem kết quả
```

---

## 📚 CÁC FILE HƯỚNG DẪN CHI TIẾT

Bạn có **4 files hướng dẫn phần cứng** trong folder `hardware/`:

### 1️⃣ **QUICK_REFERENCE_CARD.txt** ⭐⭐⭐
📁 `hardware/QUICK_REFERENCE_CARD.txt` (18 KB)

**NỘI DUNG:**
- Board layout (sơ đồ board)
- Controls: Switches, buttons
- Display: 7-segment, LEDs
- Test cases với expected results
- Quick troubleshooting

**ĐỌC FILE NÀY ĐẦU TIÊN!** - Là cheat sheet để dùng board

---

### 2️⃣ **HARDWARE_GUIDE.md** ⭐⭐⭐
📁 `hardware/HARDWARE_GUIDE.md` (9 KB)

**NỘI DUNG CHI TIẾT:**

#### **Bước 1: Cài Quartus II** (Trang đầu)
```
- Download link
- Chọn version nào
- Cài USB Blaster driver
- Verify installation
```

#### **Bước 2: Tạo Project** (Step-by-step)
```
- File → New Project Wizard
- Device selection: EP4CE6E22C8
- Add files: .v, .qsf, .sdc
- Settings
```

#### **Bước 3: Compile** (Chi tiết)
```
- Processing → Start Compilation
- Đợi ~2-3 phút
- Check reports
- Verify timing
```

#### **Bước 4: Nạp Board** (Từng bước)
```
- Cắm USB cable
- Tools → Programmer
- Hardware setup
- Load .sof file
- Program!
```

#### **Bước 5: Test & Verify**
```
- Test cases cụ thể
- Expected results
- How to read display
- Troubleshooting
```

---

### 3️⃣ **BOARD_DIAGRAM.txt**
📁 `hardware/BOARD_DIAGRAM.txt` (18 KB)

**NỘI DUNG:**
- Board layout diagram (ASCII art)
- Pin connections table
- Signal flow diagram
- Timing diagram
- Usage example với timeline
- Photo reference (board của bạn)

---

### 4️⃣ **README_HARDWARE.md**
📁 `hardware/README_HARDWARE.md` (6.5 KB)

**NỘI DUNG:**
- Overview ngắn gọn
- So sánh Full Design vs Demo
- Quick start 5 phút
- Customization tips

---

## 🚀 HƯỚNG DẪN NHANH - 5 BƯỚC

### **BƯỚC 1: Cài Quartus II** (30 phút lần đầu)

#### Download:
```
🌐 Link: https://www.intel.com/quartus
📦 Chọn: Quartus Prime Lite Edition (FREE)
💾 Size: ~5 GB
⏱️  Time: 20-30 phút download
```

#### Installation:
```
1. Chạy installer
2. Next → Next → Install
3. Chọn "Device support": Cyclone IV
4. Cài kèm ModelSim (optional, cho simulation)
5. Finish
```

#### USB Blaster Driver:
```
📁 Location: <Quartus_Install>/drivers/usb-blaster/
   
Windows:
1. Cắm board vào USB
2. Device Manager → Unknown Device
3. Update driver → Browse → Chọn folder trên
4. Install

Linux:
sudo apt-get install quartus-prime-lite
```

---

### **BƯỚC 2: Tạo Project** (5 phút)

#### Mở Quartus:
```
Start → Quartus Prime Lite
```

#### New Project Wizard:
```
File → New Project Wizard

Page 1: Directory & Name
├─ Working directory: E:\chat\hardware\quartus_project
├─ Project name: dct2d_cyclone4
└─ Top-level entity: cyclone4_top

Page 2: Project Type
└─ Empty project

Page 3: Add Files
├─ Add: E:\chat\hardware\cyclone4_top.v
├─ Add: E:\chat\hardware\cyclone4.qsf
└─ Add: E:\chat\hardware\cyclone4.sdc

Page 4: Family & Device
├─ Family: Cyclone IV E
├─ Device: EP4CE6E22C8
└─ Auto-detect (nếu board cắm USB)

Page 5: EDA Tools
└─ (Skip - none)

Page 6: Summary
└─ Finish
```

---

### **BƯỚC 3: Compile** (3 phút)

#### Bắt đầu compile:
```
Processing → Start Compilation
Hoặc: Ctrl + L
Hoặc: Click icon ▶️ "Start Compilation"
```

#### Quá trình compile:
```
Analysis & Synthesis   [██████████] 40s
Fitter                 [██████████] 60s  
Assembler             [██████████] 10s
Timing Analyzer       [██████████] 20s
────────────────────────────────────────
Total: ~2-3 phút
```

#### Kiểm tra kết quả:
```
✅ "Compilation successful"
✅ "0 errors, 0 warnings" (hoặc vài warnings không sao)

Xem reports:
📊 Compilation Report → Resource Usage
   ├─ Logic Elements: ~800 / 6,272 (13%)
   ├─ Registers: ~200 / 6,272 (3%)
   └─ Multipliers: 8 / 30 (27%)

📊 TimeQuest Timing Analyzer
   └─ Fmax: ~XX MHz (should meet 50 MHz)
```

---

### **BƯỚC 4: Nạp vào Board** (2 phút) ⭐ QUAN TRỌNG

#### Chuẩn bị:
```
1. Cắm board vào máy tính qua USB
2. Bật nguồn board (switch ON)
3. Đèn nguồn board phải sáng
```

#### Mở Programmer:
```
Tools → Programmer
Hoặc: Click icon 🔌 "Programmer"
```

#### Setup Hardware:
```
Hardware Setup button
├─ Available hardware: USB-Blaster [USB-0]
└─ Click "Close"

Nếu không thấy USB-Blaster:
❌ → Cài lại driver (xem Bước 1)
```

#### Add File:
```
1. Click "Add File..."
2. Browse: E:\chat\hardware\output_files\cyclone4_top.sof
3. Select & Open

Hoặc tự động:
- Quartus sẽ tìm file .sof trong output_files/
```

#### Program:
```
┌─────────────────────────────────────────┐
│ ☑ Program/Configure                     │
│ File: cyclone4_top.sof                  │
│ Device: EP4CE6E22 (5M)                  │
└─────────────────────────────────────────┘

Click "Start" button

Progress:
[████████████████████] 100% (10s)

✅ "100% Successful"
```

#### Verify:
```
✅ Đèn LED trên board chớp/sáng
✅ 7-segment displays hiển thị "----" hoặc số
✅ Ready để test!
```

---

### **BƯỚC 5: Test & Sử Dụng** (2 phút)

#### Test Case 1: DC Pattern
```
1. Đặt SW[1:0] = 00 (cả 2 switches xuống)
   SW1: ↓ OFF
   SW0: ↓ OFF

2. Đặt SW[3:2] = 00
   SW3: ↓ OFF
   SW2: ↓ OFF

3. Nhấn KEY[0] (nút bấm)
   → Board tính toán DCT

4. Quan sát LEDs:
   LED[0] → ● (IDLE)
   LED[1] → ● (LOADING) - chớp nhanh
   LED[2] → ● (COMPUTING) - chớp
   LED[3] → ● (DISPLAY) - sáng

5. Đọc 7-segment:
   Hiển thị: 0 0 0 0
   → Đúng! (DC pattern = all zeros)
```

#### Test Case 2: Checkerboard ⭐
```
1. Đặt SW[1:0] = 01
   SW1: ↓ OFF
   SW0: ↑ ON

2. Đặt SW[3:2] = 00

3. Nhấn KEY[0]

4. Kết quả 7-segment:
   Hiển thị: F F 8 0
   
   Giải thích:
   FF80 (hex) = -128 (decimal)
   → Đúng! (Checkerboard DC coefficient)
```

#### Test Case 3: Impulse
```
1. Đặt SW[1:0] = 11
   SW1: ↑ ON
   SW0: ↑ ON

2. Nhấn KEY[0]

3. Kết quả:
   Hiển thị: 7 F ~ ~ (số dương lớn)
   → Đúng! (Impulse có DC lớn)
```

---

## 📖 ĐỌC THÊM CHI TIẾT

### Trong folder `hardware/`:

```
📁 hardware/
├─ 📄 QUICK_REFERENCE_CARD.txt ⭐⭐⭐
│  └─ Cheat sheet, đọc khi dùng board
│
├─ 📄 HARDWARE_GUIDE.md ⭐⭐⭐
│  └─ Step-by-step đầy đủ
│
├─ 📄 BOARD_DIAGRAM.txt
│  └─ Sơ đồ board chi tiết
│
├─ 📄 README_HARDWARE.md
│  └─ Overview nhanh
│
├─ 💻 cyclone4_top.v
│  └─ Code Verilog (có comments chi tiết)
│
├─ 📋 cyclone4.qsf
│  └─ Pin assignments
│
└─ ⏱️  cyclone4.sdc
   └─ Timing constraints
```

---

## 🎮 CONTROLS - CÁCH DÙNG BOARD

### DIP Switches (SW[3:0])

```
┌─────────────────────────────────────┐
│ SW[1:0]: CHỌN PATTERN              │
├─────────────────────────────────────┤
│ 00 = DC (all 128)                  │
│      Input: Tất cả pixels = 128    │
│                                     │
│ 01 = Checkerboard ⭐                │
│      Input: 255 0 255 0 ...        │
│                                     │
│ 10 = Gradient                      │
│      Input: 0→32→64→...            │
│                                     │
│ 11 = Impulse                       │
│      Input: 255 0 0 0 ...          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ SW[3:2]: CHỌN COEFFICIENT HIỂN THỊ │
├─────────────────────────────────────┤
│ 00 = Coefficient #0 (DC)           │
│ 01 = Coefficient #2                │
│ 10 = Coefficient #4                │
│ 11 = Coefficient #6                │
└─────────────────────────────────────┘
```

### Push Buttons (KEY[3:0])

```
KEY[0] → BẮT ĐẦU TÍNH TOÁN
         Nhấn xuống để compute DCT

KEY[1] → RESET VỀ IDLE
         Quay về trạng thái ban đầu

KEY[2] → (Reserved)
KEY[3] → (Reserved)
```

### 7-Segment Display

```
   HEX3   HEX2   HEX1   HEX0
   ┌───┐ ┌───┐ ┌───┐ ┌───┐
   │ F │ │ F │ │ 8 │ │ 0 │
   └───┘ └───┘ └───┘ └───┘

Hiển thị: FF80 (hexadecimal)

Đổi sang decimal:
- Nếu chữ số đầu < 8 → Số dương
- Nếu chữ số đầu ≥ 8 → Số âm

FF80 = -(10000 - FF80) = -128
```

### Status LEDs

```
LED[0] = ● IDLE      (sẵn sàng)
LED[1] = ● LOADING   (đang nạp dữ liệu)
LED[2] = ● COMPUTING (đang tính toán)
LED[3] = ● DISPLAY   (hoàn thành!)
LED[7:4] = (Reserved)
```

---

## 🐛 TROUBLESHOOTING

### ❌ "USB-Blaster not found"

**Nguyên nhân:** Driver chưa cài hoặc cable lỏng

**Giải pháp:**
```
1. Kiểm tra cable USB (thử cable khác)
2. Kiểm tra nguồn board (switch ON)
3. Cài lại driver USB Blaster:
   Device Manager → Update driver
   Browse: <Quartus>/drivers/usb-blaster
4. Thử port USB khác
5. Restart Quartus Programmer
```

---

### ❌ "Compilation failed"

**Nguyên nhân:** Lỗi syntax hoặc thiếu files

**Giải pháp:**
```
1. Check Messages window:
   - Xem dòng lỗi cụ thể
   - Note: file nào, line nào

2. Verify files đã add:
   ✓ cyclone4_top.v
   ✓ cyclone4.qsf
   ✓ cyclone4.sdc

3. Check device:
   Assignments → Device
   → Phải là EP4CE6E22C8

4. Re-import files:
   Project → Add/Remove Files
```

---

### ❌ "Timing requirements not met"

**Nguyên nhân:** Clock quá nhanh cho design

**Giải pháp:**
```
1. Xem Timing Analyzer report
2. Note: Fmax achieved

Nếu Fmax < 50 MHz:
   → Đơn giản hóa design
   → Hoặc giảm clock xuống 25 MHz

Edit cyclone4.sdc:
   create_clock -period 40.000 ...
   (40ns = 25 MHz)
```

---

### ❌ "Board không phản hồi"

**Nguyên nhân:** Code chưa nạp đúng hoặc board lỗi

**Giải pháp:**
```
1. Reprogram board:
   Tools → Programmer → Start

2. Power cycle:
   Tắt board → đợi 5s → Bật lại

3. Check LED nguồn:
   Phải sáng

4. Try simple blink test:
   Nạp code đơn giản (blink LED)
```

---

### ❌ "7-segment hiển thị sai"

**Nguyên nhân:** Switch position sai hoặc chưa compute

**Giải pháp:**
```
1. Check switches:
   Đúng position theo test case?

2. Press KEY[0]:
   Đã nhấn nút compute chưa?

3. Wait for LED[3]:
   LED[3] sáng = done

4. Verify pattern:
   So sánh với expected results
   trong QUICK_REFERENCE_CARD.txt
```

---

## 📊 EXPECTED RESULTS

### Checkerboard (SW[1:0]=01)
```
7-segment: F F 8 0
Decimal: -128
✅ CORRECT!
```

### DC (SW[1:0]=00)
```
7-segment: 0 0 0 0
Decimal: 0
✅ CORRECT!
```

### Impulse (SW[1:0]=11)
```
7-segment: 7 F ~ ~
Decimal: ~32000 (positive large)
✅ CORRECT!
```

### Gradient (SW[1:0]=10)
```
7-segment: ~ ~ ~ ~ (negative)
Decimal: Large negative
✅ CORRECT!
```

---

## 🎓 VIDEO TUTORIAL (Nếu cần)

Các bước chính được mô tả trong:
- `hardware/HARDWARE_GUIDE.md` - Text chi tiết
- `hardware/BOARD_DIAGRAM.txt` - Sơ đồ visual
- `hardware/QUICK_REFERENCE_CARD.txt` - Quick ref

---

## ✅ CHECKLIST

### Trước khi bắt đầu:
- [ ] Có board Cyclone IV
- [ ] Có USB cable
- [ ] Download Quartus II
- [ ] Cài USB Blaster driver

### Lần đầu programming:
- [ ] Quartus installed
- [ ] Project created
- [ ] Files added (.v, .qsf, .sdc)
- [ ] Compilation successful
- [ ] No timing violations
- [ ] USB Blaster detected
- [ ] Board powered ON

### Mỗi lần sau:
- [ ] Open project
- [ ] (Modify code if needed)
- [ ] Compile (Ctrl+L)
- [ ] Program (Tools → Programmer → Start)
- [ ] Test!

---

## 🔄 LẦN SAU (5 phút)

Khi đã setup xong lần đầu, lần sau chỉ cần:

```
1. Mở Quartus                    (10s)
2. Open project                  (5s)
3. (Modify code nếu cần)         (optional)
4. Compile (Ctrl+L)              (2 phút)
5. Program (Ctrl+P or Tools)     (10s)
6. Test!                         (1 phút)
────────────────────────────────────────
Total: ~5 phút
```

---

## 💡 TIPS

### Compile nhanh hơn:
```
Processing → Start → Start Analysis & Elaboration
→ Chỉ check syntax, không full compile
→ Nhanh hơn 10×
```

### Programming nhanh hơn:
```
Tools → Programmer
→ Tick "Auto Detect"
→ Không cần browse .sof file mỗi lần
```

### Xem waveform (debug):
```
Tools → Signal Tap Logic Analyzer
→ Xem tín hiệu internal
→ Cần để debug nếu có vấn đề
```

---

## 📚 ĐỌC THÊM

### Chi tiết hơn:
1. **hardware/HARDWARE_GUIDE.md** - Complete guide
2. **hardware/QUICK_REFERENCE_CARD.txt** - Quick ref
3. **hardware/BOARD_DIAGRAM.txt** - Visual guide

### Hiểu code:
1. **hardware/cyclone4_top.v** - Main code
2. **hardware/README_HARDWARE.md** - Overview

### Learning:
1. **QUICK_START.md** - DCT explained
2. **README.md** - Full docs
3. **testbench/demo_dct.py** - Run demo

---

## 🎯 TÓM TẮT

```
PHẦN CỨNG = NẠP CODE VÀO BOARD

Tools cần:
  ✓ Quartus II (FREE)
  ✓ USB cable
  ✓ Board Cyclone IV

Steps:
  1. Cài Quartus     (30 phút lần đầu)
  2. Tạo project     (5 phút)
  3. Compile         (3 phút)
  4. Nạp qua USB     (2 phút) ⭐
  5. Test!           (2 phút)

Lần sau:
  → Chỉ 5 phút (compile + program)

Files hướng dẫn:
  ✓ HARDWARE_GUIDE.md ⭐⭐⭐
  ✓ QUICK_REFERENCE_CARD.txt ⭐⭐⭐
  ✓ BOARD_DIAGRAM.txt
  ✓ README_HARDWARE.md
```

---

**BẮT ĐẦU TỪ:** `hardware/HARDWARE_GUIDE.md`

**CHÚC BẠN THÀNH CÔNG! 🚀**

---

*HUONG_DAN_PHAN_CUNG.md*  
*DCT 2D High-Speed FPGA Core v1.0*  
*Tác giả: Bé Tiến Đạt Xinh Gái*  
*October 16, 2025*

