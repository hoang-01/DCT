////////////////////////////////////////////////////////////////////////////////
// HLS Implementation of 2D DCT (8x8) for Xilinx Vitis HLS
// Alternative to RTL for rapid prototyping and comparison
// Target: >= Vitis HLS 2020.2
////////////////////////////////////////////////////////////////////////////////

#include <ap_int.h>
#include <ap_fixed.h>
#include <hls_stream.h>

// Type definitions
typedef ap_int<8>   pixel_t;      // Input pixel: 0..255
typedef ap_int<16>  coef_t;       // DCT coefficient
typedef ap_fixed<18,4> acc_t;     // Accumulator
typedef ap_fixed<16,2> cos_t;     // Cosine coefficients

// AXI Stream interface
struct axis_t {
    ap_int<16> data;
    ap_uint<1> last;
};

// DCT-II cosine coefficients (normalized by 1/sqrt(2*N))
const cos_t COS_TABLE[8][8] = {
    {0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536},
    {0.4904, 0.4157, 0.2778, 0.0975, -0.0975, -0.2778, -0.4157, -0.4904},
    {0.4619, 0.1913, -0.1913, -0.4619, -0.4619, -0.1913, 0.1913, 0.4619},
    {0.4157, -0.0975, -0.4904, -0.2778, 0.2778, 0.4904, 0.0975, -0.4157},
    {0.3536, -0.3536, -0.3536, 0.3536, 0.3536, -0.3536, -0.3536, 0.3536},
    {0.2778, -0.4904, 0.0975, 0.4157, -0.4157, -0.0975, 0.4904, -0.2778},
    {0.1913, -0.4619, 0.4619, -0.1913, -0.1913, 0.4619, -0.4619, 0.1913},
    {0.0975, -0.2778, 0.4157, -0.4904, 0.4904, -0.4157, 0.2778, -0.0975}
};

// 1D DCT-II transformation
void dct1d(coef_t in[8], coef_t out[8]) {
    #pragma HLS PIPELINE II=1
    #pragma HLS ARRAY_PARTITION variable=in complete
    #pragma HLS ARRAY_PARTITION variable=out complete
    
    DCT_COEF_LOOP: for (int k = 0; k < 8; k++) {
        #pragma HLS UNROLL
        acc_t sum = 0;
        
        DCT_SUM_LOOP: for (int n = 0; n < 8; n++) {
            #pragma HLS UNROLL
            sum += (acc_t)in[n] * COS_TABLE[k][n];
        }
        
        out[k] = (coef_t)(sum * 4);  // Scale factor
    }
}

// 2D DCT: Row transform -> Transpose -> Column transform
void dct2d_8x8(pixel_t block_in[8][8], coef_t block_out[8][8]) {
    #pragma HLS ARRAY_PARTITION variable=block_in complete dim=2
    #pragma HLS ARRAY_PARTITION variable=block_out complete dim=2
    
    // Intermediate buffers
    coef_t row_dct[8][8];
    #pragma HLS ARRAY_PARTITION variable=row_dct complete dim=2
    
    coef_t transposed[8][8];
    #pragma HLS ARRAY_PARTITION variable=transposed complete dim=2
    
    // Row DCT
    ROW_DCT_LOOP: for (int i = 0; i < 8; i++) {
        #pragma HLS UNROLL
        coef_t row_in[8];
        coef_t row_out[8];
        #pragma HLS ARRAY_PARTITION variable=row_in complete
        #pragma HLS ARRAY_PARTITION variable=row_out complete
        
        // Convert to signed and center
        for (int j = 0; j < 8; j++) {
            #pragma HLS UNROLL
            row_in[j] = (coef_t)block_in[i][j] - 128;
        }
        
        dct1d(row_in, row_out);
        
        for (int j = 0; j < 8; j++) {
            #pragma HLS UNROLL
            row_dct[i][j] = row_out[j];
        }
    }
    
    // Transpose
    TRANSPOSE_LOOP_I: for (int i = 0; i < 8; i++) {
        #pragma HLS UNROLL
        TRANSPOSE_LOOP_J: for (int j = 0; j < 8; j++) {
            #pragma HLS UNROLL
            transposed[i][j] = row_dct[j][i];
        }
    }
    
    // Column DCT (on transposed data = column DCT on original)
    COL_DCT_LOOP: for (int i = 0; i < 8; i++) {
        #pragma HLS UNROLL
        coef_t col_in[8];
        coef_t col_out[8];
        #pragma HLS ARRAY_PARTITION variable=col_in complete
        #pragma HLS ARRAY_PARTITION variable=col_out complete
        
        for (int j = 0; j < 8; j++) {
            #pragma HLS UNROLL
            col_in[j] = transposed[i][j];
        }
        
        dct1d(col_in, col_out);
        
        for (int j = 0; j < 8; j++) {
            #pragma HLS UNROLL
            block_out[i][j] = col_out[j];
        }
    }
}

// Top-level streaming interface
void dct2d_stream(
    hls::stream<pixel_t> &in_stream,
    hls::stream<coef_t> &out_stream
) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE axis port=in_stream
    #pragma HLS INTERFACE axis port=out_stream
    
    pixel_t block_in[8][8];
    #pragma HLS ARRAY_PARTITION variable=block_in complete dim=2
    
    coef_t block_out[8][8];
    #pragma HLS ARRAY_PARTITION variable=block_out complete dim=2
    
    // Read 8x8 block
    READ_LOOP: for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            #pragma HLS PIPELINE II=1
            block_in[i][j] = in_stream.read();
        }
    }
    
    // Compute 2D DCT
    dct2d_8x8(block_in, block_out);
    
    // Write output
    WRITE_LOOP: for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            #pragma HLS PIPELINE II=1
            out_stream.write(block_out[i][j]);
        }
    }
}

// AXI4-Stream wrapper (for full interface compatibility)
void dct2d_top(
    hls::stream<axis_t> &s_axis,
    hls::stream<axis_t> &m_axis
) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE axis port=s_axis
    #pragma HLS INTERFACE axis port=m_axis
    #pragma HLS DATAFLOW
    
    pixel_t block_in[8][8];
    coef_t block_out[8][8];
    
    // Read from AXI Stream
    for (int i = 0; i < 64; i++) {
        #pragma HLS PIPELINE II=1
        axis_t in_data = s_axis.read();
        block_in[i/8][i%8] = (pixel_t)in_data.data;
    }
    
    // Process
    dct2d_8x8(block_in, block_out);
    
    // Write to AXI Stream
    for (int i = 0; i < 64; i++) {
        #pragma HLS PIPELINE II=1
        axis_t out_data;
        out_data.data = (ap_int<16>)block_out[i/8][i%8];
        out_data.last = (i == 63) ? 1 : 0;
        m_axis.write(out_data);
    }
}

