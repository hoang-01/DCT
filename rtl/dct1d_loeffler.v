////////////////////////////////////////////////////////////////////////////////
// 1D DCT-II (8-point) - Loeffler Algorithm
// High-speed pipelined implementation with fixed-point Q1.14
// Throughput: 1 sample/cycle (after initial latency ~12 cycles)
// Input: 8-bit signed samples (-128..127)
// Output: 16-bit DCT coefficients
////////////////////////////////////////////////////////////////////////////////

module dct1d_loeffler #(
    parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = 16,
    parameter COEF_WIDTH = 16  // Q1.14 format
)(
    input  wire                           clk,
    input  wire                           rst_n,
    
    // Input stream: 8 samples in sequence
    input  wire                           in_valid,
    input  wire signed [INPUT_WIDTH-1:0]  in_sample,
    input  wire [2:0]                     in_index,   // 0..7
    input  wire                           in_last,    // marks last sample of block
    
    // Output stream: 8 DCT coefficients in sequence
    output reg                            out_valid,
    output reg  signed [OUTPUT_WIDTH-1:0] out_coef,
    output reg  [2:0]                     out_index,
    output reg                            out_last
);

    // DCT-II coefficients (Q1.14 format)
    // cos(k*pi/16) where k = 1,2,3,4,5,6,7
    localparam signed [COEF_WIDTH-1:0] C1 = 16'sd16069; // cos(1*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C2 = 16'sd15137; // cos(2*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C3 = 16'sd13623; // cos(3*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C4 = 16'sd11585; // cos(4*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C5 = 16'sd9102;  // cos(5*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C6 = 16'sd6270;  // cos(6*pi/16) * 2^14
    localparam signed [COEF_WIDTH-1:0] C7 = 16'sd3196;  // cos(7*pi/16) * 2^14
    
    localparam signed [COEF_WIDTH-1:0] S2 = 16'sd11585; // 1/sqrt(2) * 2^14
    
    // Input buffer for 8 samples
    reg signed [INPUT_WIDTH-1:0] x [0:7];
    reg [2:0] sample_count;
    reg block_ready;
    
    // Stage 0: Input buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count <= 0;
            block_ready <= 0;
        end else begin
            if (in_valid) begin
                x[in_index] <= in_sample;
                if (in_last) begin
                    sample_count <= 0;
                    block_ready <= 1;
                end else begin
                    sample_count <= sample_count + 1;
                end
            end else begin
                block_ready <= 0;
            end
        end
    end
    
    // Pipeline Stage 1: First butterfly (addition/subtraction)
    reg signed [INPUT_WIDTH:0] s1_a0, s1_a1, s1_a2, s1_a3;
    reg signed [INPUT_WIDTH:0] s1_b0, s1_b1, s1_b2, s1_b3;
    reg s1_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 0;
        end else begin
            s1_valid <= block_ready;
            if (block_ready) begin
                s1_a0 <= x[0] + x[7];
                s1_a1 <= x[1] + x[6];
                s1_a2 <= x[2] + x[5];
                s1_a3 <= x[3] + x[4];
                s1_b0 <= x[0] - x[7];
                s1_b1 <= x[1] - x[6];
                s1_b2 <= x[2] - x[5];
                s1_b3 <= x[3] - x[4];
            end
        end
    end
    
    // Pipeline Stage 2: Second butterfly
    reg signed [INPUT_WIDTH+1:0] s2_c0, s2_c1, s2_c2, s2_c3;
    reg signed [INPUT_WIDTH+1:0] s2_d0, s2_d1, s2_d2, s2_d3;
    reg s2_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 0;
        end else begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_c0 <= s1_a0 + s1_a3;
                s2_c1 <= s1_a1 + s1_a2;
                s2_c2 <= s1_a1 - s1_a2;
                s2_c3 <= s1_a0 - s1_a3;
                s2_d0 <= s1_b0;
                s2_d1 <= s1_b1;
                s2_d2 <= s1_b2;
                s2_d3 <= s1_b3;
            end
        end
    end
    
    // Pipeline Stage 3: Even part processing
    reg signed [OUTPUT_WIDTH-1:0] s3_X0, s3_X2, s3_X4, s3_X6;
    reg signed [COEF_WIDTH+INPUT_WIDTH+1:0] s3_t0, s3_t1, s3_t2, s3_t3;
    reg s3_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_valid <= 0;
        end else begin
            s3_valid <= s2_valid;
            if (s2_valid) begin
                // DC and X4
                s3_X0 <= (s2_c0 + s2_c1) >>> 0;
                s3_X4 <= (s2_c0 - s2_c1) >>> 0;
                
                // X2 and X6 with rotation
                s3_t0 <= (s2_c2 * C6);
                s3_t1 <= (s2_c3 * C2);
                s3_t2 <= (s2_c2 * C2);
                s3_t3 <= (s2_c3 * C6);
            end
        end
    end
    
    // Pipeline Stage 4: Complete even part and start odd part
    reg signed [OUTPUT_WIDTH-1:0] s4_X0, s4_X2, s4_X4, s4_X6;
    reg signed [COEF_WIDTH+INPUT_WIDTH+1:0] s4_odd [0:7];
    reg s4_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s4_valid <= 0;
        end else begin
            s4_valid <= s3_valid;
            if (s3_valid) begin
                s4_X0 <= s3_X0;
                s4_X4 <= s3_X4;
                s4_X2 <= (s3_t0 + s3_t1) >>> 14;
                s4_X6 <= (s3_t2 - s3_t3) >>> 14;
                
                // Odd part rotations
                s4_odd[0] <= (s2_d0 * C7);
                s4_odd[1] <= (s2_d1 * C5);
                s4_odd[2] <= (s2_d2 * C3);
                s4_odd[3] <= (s2_d3 * C1);
                s4_odd[4] <= (s2_d0 * C1);
                s4_odd[5] <= (s2_d1 * C3);
                s4_odd[6] <= (s2_d2 * C5);
                s4_odd[7] <= (s2_d3 * C7);
            end
        end
    end
    
    // Pipeline Stage 5: Odd part butterfly
    reg signed [OUTPUT_WIDTH-1:0] s5_X0, s5_X2, s5_X4, s5_X6;
    reg signed [COEF_WIDTH+INPUT_WIDTH+2:0] s5_p0, s5_p1, s5_p2, s5_p3;
    reg s5_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s5_valid <= 0;
        end else begin
            s5_valid <= s4_valid;
            if (s4_valid) begin
                s5_X0 <= s4_X0;
                s5_X2 <= s4_X2;
                s5_X4 <= s4_X4;
                s5_X6 <= s4_X6;
                
                s5_p0 <= (s4_odd[0] + s4_odd[3]) >>> 14;
                s5_p1 <= (s4_odd[1] + s4_odd[2]) >>> 14;
                s5_p2 <= (s4_odd[1] - s4_odd[2]) >>> 14;
                s5_p3 <= (s4_odd[0] - s4_odd[3]) >>> 14;
            end
        end
    end
    
    // Pipeline Stage 6: Final odd coefficients
    reg signed [OUTPUT_WIDTH-1:0] s6_X [0:7];
    reg s6_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s6_valid <= 0;
        end else begin
            s6_valid <= s5_valid;
            if (s5_valid) begin
                s6_X[0] <= s5_X0;
                s6_X[4] <= s5_X4;
                s6_X[2] <= s5_X2;
                s6_X[6] <= s5_X6;
                
                // Odd coefficients
                s6_X[1] <= (s5_p0 + s5_p1);
                s6_X[7] <= (s5_p0 - s5_p1);
                s6_X[5] <= (((s5_p2 + s5_p3) * S2) >>> 14);
                s6_X[3] <= (((s5_p3 - s5_p2) * S2) >>> 14);
            end
        end
    end
    
    // Output serializer
    reg [2:0] out_cnt;
    reg outputting;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            out_cnt <= 0;
            outputting <= 0;
        end else begin
            if (s6_valid && !outputting) begin
                outputting <= 1;
                out_cnt <= 0;
                out_valid <= 1;
                out_coef <= s6_X[0];
                out_index <= 0;
                out_last <= 0;
            end else if (outputting) begin
                if (out_cnt < 7) begin
                    out_cnt <= out_cnt + 1;
                    out_coef <= s6_X[out_cnt + 1];
                    out_index <= out_cnt + 1;
                    out_last <= (out_cnt == 6);
                    out_valid <= 1;
                end else begin
                    outputting <= 0;
                    out_valid <= 0;
                end
            end else begin
                out_valid <= 0;
            end
        end
    end

endmodule

