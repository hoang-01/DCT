////////////////////////////////////////////////////////////////////////////////
// DCT 2D Demo for Cyclone IV FPGA Development Board
// Simplified version with on-board I/O demonstration
// - Uses switches to input test pattern selection
// - Uses 7-segment displays to show DCT coefficient values
// - Push button to trigger computation
////////////////////////////////////////////////////////////////////////////////

module cyclone4_top (
    // Clock and reset
    input  wire        clk_50mhz,        // 50 MHz onboard clock
    input  wire        rst_n,             // Reset button (active low)
    
    // DIP switches (for test pattern selection)
    input  wire [3:0]  sw,                // 4 DIP switches
    
    // Push buttons
    input  wire [3:0]  key,               // 4 push buttons (active low)
    
    // 7-segment displays
    output wire [6:0]  hex0,              // Rightmost digit
    output wire [6:0]  hex1,
    output wire [6:0]  hex2,
    output wire [6:0]  hex3,              // Leftmost digit
    
    // LEDs (optional status)
    output wire [7:0]  led                // 8 LEDs for status
);

    // Internal signals
    wire        clk;
    wire        reset;
    wire        compute_trigger;
    reg  [15:0] display_value;
    reg  [7:0]  status_leds;
    
    // Clock and reset management
    assign clk = clk_50mhz;
    assign reset = ~rst_n;  // Active high internally
    
    // Button debouncing for compute trigger
    reg [1:0] key0_sync;
    always @(posedge clk or posedge reset) begin
        if (reset)
            key0_sync <= 2'b11;
        else
            key0_sync <= {key0_sync[0], key[0]};
    end
    
    assign compute_trigger = (key0_sync == 2'b10);  // Falling edge
    
    // Test pattern ROM (pre-computed simple patterns)
    reg signed [7:0] test_pattern [0:63];
    
    // Initialize test patterns based on switch selection
    integer i;
    always @(*) begin
        case (sw[1:0])
            2'b00: begin  // DC pattern (all 128)
                for (i = 0; i < 64; i = i + 1)
                    test_pattern[i] = 8'd128;
            end
            2'b01: begin  // Checkerboard
                for (i = 0; i < 64; i = i + 1)
                    test_pattern[i] = ((i[3] ^ i[0]) ? 8'd255 : 8'd0);
            end
            2'b10: begin  // Horizontal gradient
                for (i = 0; i < 64; i = i + 1)
                    test_pattern[i] = {i[2:0], 5'b00000};
            end
            2'b11: begin  // Impulse (single pixel)
                for (i = 0; i < 64; i = i + 1)
                    test_pattern[i] = (i == 0) ? 8'd255 : 8'd0;
            end
        endcase
    end
    
    // DCT computation state machine
    localparam IDLE = 0, LOAD = 1, COMPUTE = 2, DISPLAY = 3;
    reg [2:0] state;
    reg [5:0] pixel_index;
    reg [5:0] coef_index;
    reg [15:0] dct_coefficients [0:63];
    
    // DCT core signals
    reg                  dct_in_valid;
    reg  signed [7:0]    dct_in_sample;
    reg  [2:0]           dct_in_index;
    reg                  dct_in_last;
    wire                 dct_out_valid;
    wire signed [15:0]   dct_out_coef;
    wire [2:0]           dct_out_index;
    wire                 dct_out_last;
    
    // Simplified 1D DCT for demonstration
    // Note: Full 2D DCT requires significant resources
    // This demo uses 1D DCT on first row only for simplicity
    dct1d_simple dct_row (
        .clk(clk),
        .rst_n(~reset),
        .in_valid(dct_in_valid),
        .in_sample(dct_in_sample),
        .in_index(dct_in_index),
        .in_last(dct_in_last),
        .out_valid(dct_out_valid),
        .out_coef(dct_out_coef),
        .out_index(dct_out_index),
        .out_last(dct_out_last)
    );
    
    // Main control FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            pixel_index <= 0;
            coef_index <= 0;
            dct_in_valid <= 0;
            display_value <= 0;
            status_leds <= 8'h01;
        end else begin
            case (state)
                IDLE: begin
                    status_leds <= 8'h01;
                    if (compute_trigger) begin
                        state <= LOAD;
                        pixel_index <= 0;
                        coef_index <= 0;
                    end
                    // Display selected coefficient
                    display_value <= dct_coefficients[sw[3:2] * 2];
                end
                
                LOAD: begin
                    status_leds <= 8'h02;
                    // Load first row (8 pixels) into DCT
                    dct_in_valid <= 1;
                    dct_in_sample <= test_pattern[pixel_index];
                    dct_in_index <= pixel_index[2:0];
                    dct_in_last <= (pixel_index == 7);
                    
                    if (pixel_index == 7) begin
                        state <= COMPUTE;
                        pixel_index <= 0;
                    end else begin
                        pixel_index <= pixel_index + 1;
                    end
                end
                
                COMPUTE: begin
                    status_leds <= 8'h04;
                    dct_in_valid <= 0;
                    
                    // Collect DCT output
                    if (dct_out_valid) begin
                        dct_coefficients[coef_index] <= dct_out_coef;
                        coef_index <= coef_index + 1;
                        
                        if (dct_out_last) begin
                            state <= DISPLAY;
                        end
                    end
                end
                
                DISPLAY: begin
                    status_leds <= 8'h08;
                    // Display first coefficient by default
                    display_value <= dct_coefficients[sw[3:2] * 2];
                    
                    // Return to idle after displaying
                    if (key[1] == 0) begin  // Press key1 to return
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 7-segment display driver
    wire [3:0] digit0, digit1, digit2, digit3;
    
    // Split 16-bit value into 4 hex digits
    assign digit0 = display_value[3:0];
    assign digit1 = display_value[7:4];
    assign digit2 = display_value[11:8];
    assign digit3 = display_value[15:12];
    
    // Hex to 7-segment decoder
    hex_to_7seg hex_dec0 (.hex(digit0), .seg(hex0));
    hex_to_7seg hex_dec1 (.hex(digit1), .seg(hex1));
    hex_to_7seg hex_dec2 (.hex(digit2), .seg(hex2));
    hex_to_7seg hex_dec3 (.hex(digit3), .seg(hex3));
    
    // LED output
    assign led = status_leds;

endmodule


////////////////////////////////////////////////////////////////////////////////
// Simplified 1D DCT (8-point) for demonstration
// Uses matrix multiplication (less efficient but simpler for demo)
////////////////////////////////////////////////////////////////////////////////
module dct1d_simple (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  in_valid,
    input  wire signed [7:0]     in_sample,
    input  wire [2:0]            in_index,
    input  wire                  in_last,
    output reg                   out_valid,
    output reg  signed [15:0]    out_coef,
    output reg  [2:0]            out_index,
    output reg                   out_last
);

    // Input buffer
    reg signed [7:0] samples [0:7];
    reg buffer_ready;
    
    // Buffer input samples
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_ready <= 0;
        end else begin
            if (in_valid) begin
                samples[in_index] <= in_sample - 8'sd128;  // Center around 0
                if (in_last) begin
                    buffer_ready <= 1;
                end
            end else begin
                buffer_ready <= 0;
            end
        end
    end
    
    // DCT computation (simplified - computes one coefficient at a time)
    reg [2:0] k;  // Current DCT coefficient index
    reg computing;
    reg signed [31:0] accumulator;
    reg [2:0] n;  // Current sample index
    
    // Pre-computed DCT cosine values (scaled by 256 for integer math)
    // cos(pi * k * (2n + 1) / 16) * 256
    wire signed [15:0] cos_table [0:63];
    
    // Initialize cosine table (8x8 = 64 values)
    // k=0,n=0..7
    assign cos_table[0] = 16'sd256;   assign cos_table[1] = 16'sd256;
    assign cos_table[2] = 16'sd256;   assign cos_table[3] = 16'sd256;
    assign cos_table[4] = 16'sd256;   assign cos_table[5] = 16'sd256;
    assign cos_table[6] = 16'sd256;   assign cos_table[7] = 16'sd256;
    
    // k=1,n=0..7
    assign cos_table[8]  = 16'sd251;  assign cos_table[9]  = 16'sd212;
    assign cos_table[10] = 16'sd142;  assign cos_table[11] = 16'sd49;
    assign cos_table[12] = -16'sd49;  assign cos_table[13] = -16'sd142;
    assign cos_table[14] = -16'sd212; assign cos_table[15] = -16'sd251;
    
    // k=2,n=0..7
    assign cos_table[16] = 16'sd236;  assign cos_table[17] = 16'sd98;
    assign cos_table[18] = -16'sd98;  assign cos_table[19] = -16'sd236;
    assign cos_table[20] = -16'sd236; assign cos_table[21] = -16'sd98;
    assign cos_table[22] = 16'sd98;   assign cos_table[23] = 16'sd236;
    
    // k=3,n=0..7
    assign cos_table[24] = 16'sd212;  assign cos_table[25] = -16'sd49;
    assign cos_table[26] = -16'sd251; assign cos_table[27] = -16'sd142;
    assign cos_table[28] = 16'sd142;  assign cos_table[29] = 16'sd251;
    assign cos_table[30] = 16'sd49;   assign cos_table[31] = -16'sd212;
    
    // k=4,n=0..7
    assign cos_table[32] = 16'sd181;  assign cos_table[33] = -16'sd181;
    assign cos_table[34] = -16'sd181; assign cos_table[35] = 16'sd181;
    assign cos_table[36] = 16'sd181;  assign cos_table[37] = -16'sd181;
    assign cos_table[38] = -16'sd181; assign cos_table[39] = 16'sd181;
    
    // k=5,n=0..7  
    assign cos_table[40] = 16'sd142;  assign cos_table[41] = -16'sd251;
    assign cos_table[42] = 16'sd49;   assign cos_table[43] = 16'sd212;
    assign cos_table[44] = -16'sd212; assign cos_table[45] = -16'sd49;
    assign cos_table[46] = 16'sd251;  assign cos_table[47] = -16'sd142;
    
    // k=6,n=0..7
    assign cos_table[48] = 16'sd98;   assign cos_table[49] = -16'sd236;
    assign cos_table[50] = 16'sd236;  assign cos_table[51] = -16'sd98;
    assign cos_table[52] = -16'sd98;  assign cos_table[53] = 16'sd236;
    assign cos_table[54] = -16'sd236; assign cos_table[55] = 16'sd98;
    
    // k=7,n=0..7
    assign cos_table[56] = 16'sd49;   assign cos_table[57] = -16'sd142;
    assign cos_table[58] = 16'sd212;  assign cos_table[59] = -16'sd251;
    assign cos_table[60] = 16'sd251;  assign cos_table[61] = -16'sd212;
    assign cos_table[62] = 16'sd142;  assign cos_table[63] = -16'sd49;
    
    // Computation state machine
    localparam WAIT = 0, COMPUTE_INIT = 1, COMPUTE_ACC = 2, OUTPUT = 3;
    reg [1:0] comp_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_state <= WAIT;
            out_valid <= 0;
            k <= 0;
            n <= 0;
        end else begin
            case (comp_state)
                WAIT: begin
                    out_valid <= 0;
                    if (buffer_ready) begin
                        comp_state <= COMPUTE_INIT;
                        k <= 0;
                    end
                end
                
                COMPUTE_INIT: begin
                    n <= 0;
                    accumulator <= 0;
                    comp_state <= COMPUTE_ACC;
                end
                
                COMPUTE_ACC: begin
                    // Accumulate: sum += sample[n] * cos(k,n)
                    accumulator <= accumulator + (samples[n] * cos_table[k*8 + n]);
                    
                    if (n == 7) begin
                        comp_state <= OUTPUT;
                    end else begin
                        n <= n + 1;
                    end
                end
                
                OUTPUT: begin
                    out_valid <= 1;
                    out_coef <= accumulator[23:8];  // Scale down
                    out_index <= k;
                    out_last <= (k == 7);
                    
                    if (k == 7) begin
                        comp_state <= WAIT;
                        k <= 0;
                    end else begin
                        k <= k + 1;
                        comp_state <= COMPUTE_INIT;
                    end
                end
            endcase
        end
    end

endmodule


////////////////////////////////////////////////////////////////////////////////
// Hex to 7-segment decoder
// Segment encoding: {g, f, e, d, c, b, a}
////////////////////////////////////////////////////////////////////////////////
module hex_to_7seg (
    input  wire [3:0] hex,
    output reg  [6:0] seg
);

    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000;  // 0
            4'h1: seg = 7'b1111001;  // 1
            4'h2: seg = 7'b0100100;  // 2
            4'h3: seg = 7'b0110000;  // 3
            4'h4: seg = 7'b0011001;  // 4
            4'h5: seg = 7'b0010010;  // 5
            4'h6: seg = 7'b0000010;  // 6
            4'h7: seg = 7'b1111000;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0010000;  // 9
            4'hA: seg = 7'b0001000;  // A
            4'hB: seg = 7'b0000011;  // b
            4'hC: seg = 7'b1000110;  // C
            4'hD: seg = 7'b0100001;  // d
            4'hE: seg = 7'b0000110;  // E
            4'hF: seg = 7'b0001110;  // F
        endcase
    end

endmodule

