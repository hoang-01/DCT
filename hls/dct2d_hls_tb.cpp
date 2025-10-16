////////////////////////////////////////////////////////////////////////////////
// HLS Testbench for DCT 2D
////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <cmath>
#include <cstdlib>
#include "dct2d_hls.cpp"

using namespace std;

// Reference 1D DCT-II (for verification)
void reference_dct1d(double in[8], double out[8]) {
    for (int k = 0; k < 8; k++) {
        double sum = 0.0;
        for (int n = 0; n < 8; n++) {
            sum += in[n] * cos(M_PI * k * (2*n + 1) / 16.0);
        }
        out[k] = sum;
    }
}

// Reference 2D DCT-II
void reference_dct2d(double in[8][8], double out[8][8]) {
    double temp[8][8];
    
    // Row DCT
    for (int i = 0; i < 8; i++) {
        double row_in[8], row_out[8];
        for (int j = 0; j < 8; j++) {
            row_in[j] = in[i][j] - 128.0;  // Center
        }
        reference_dct1d(row_in, row_out);
        for (int j = 0; j < 8; j++) {
            temp[i][j] = row_out[j];
        }
    }
    
    // Column DCT
    for (int j = 0; j < 8; j++) {
        double col_in[8], col_out[8];
        for (int i = 0; i < 8; i++) {
            col_in[i] = temp[i][j];
        }
        reference_dct1d(col_in, col_out);
        for (int i = 0; i < 8; i++) {
            out[i][j] = col_out[i];
        }
    }
}

// Compare results
bool compare_results(coef_t hw[8][8], double sw[8][8], int tolerance = 50) {
    int max_error = 0;
    double mse = 0.0;
    bool pass = true;
    
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            int error = abs(hw[i][j].to_int() - (int)round(sw[i][j]));
            if (error > max_error) max_error = error;
            mse += error * error;
            
            if (error > tolerance) {
                cout << "Mismatch at [" << i << "][" << j << "]: "
                     << "HW=" << hw[i][j].to_int() 
                     << " SW=" << (int)round(sw[i][j])
                     << " Error=" << error << endl;
                pass = false;
            }
        }
    }
    
    mse /= 64.0;
    cout << "Max Error: " << max_error << endl;
    cout << "RMSE: " << sqrt(mse) << endl;
    
    return pass;
}

int main() {
    cout << "======================================" << endl;
    cout << "DCT 2D HLS Testbench" << endl;
    cout << "======================================" << endl;
    
    int tests_passed = 0;
    int tests_total = 0;
    
    // Test 1: DC block
    {
        cout << "\nTest 1: DC Block (all 128)" << endl;
        tests_total++;
        
        pixel_t block_in[8][8];
        coef_t block_out[8][8];
        double ref_out[8][8];
        double ref_in[8][8];
        
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                block_in[i][j] = 128;
                ref_in[i][j] = 128;
            }
        }
        
        dct2d_8x8(block_in, block_out);
        reference_dct2d(ref_in, ref_out);
        
        if (compare_results(block_out, ref_out)) {
            cout << "PASSED" << endl;
            tests_passed++;
        } else {
            cout << "FAILED" << endl;
        }
    }
    
    // Test 2: Impulse
    {
        cout << "\nTest 2: Impulse (single pixel)" << endl;
        tests_total++;
        
        pixel_t block_in[8][8];
        coef_t block_out[8][8];
        double ref_out[8][8];
        double ref_in[8][8];
        
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                block_in[i][j] = (i == 0 && j == 0) ? 255 : 0;
                ref_in[i][j] = (i == 0 && j == 0) ? 255 : 0;
            }
        }
        
        dct2d_8x8(block_in, block_out);
        reference_dct2d(ref_in, ref_out);
        
        if (compare_results(block_out, ref_out)) {
            cout << "PASSED" << endl;
            tests_passed++;
        } else {
            cout << "FAILED" << endl;
        }
    }
    
    // Test 3: Checkerboard
    {
        cout << "\nTest 3: Checkerboard" << endl;
        tests_total++;
        
        pixel_t block_in[8][8];
        coef_t block_out[8][8];
        double ref_out[8][8];
        double ref_in[8][8];
        
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                int val = ((i + j) % 2 == 0) ? 255 : 0;
                block_in[i][j] = val;
                ref_in[i][j] = val;
            }
        }
        
        dct2d_8x8(block_in, block_out);
        reference_dct2d(ref_in, ref_out);
        
        if (compare_results(block_out, ref_out)) {
            cout << "PASSED" << endl;
            tests_passed++;
        } else {
            cout << "FAILED" << endl;
        }
    }
    
    // Test 4: Random
    {
        cout << "\nTest 4: Random block" << endl;
        tests_total++;
        
        pixel_t block_in[8][8];
        coef_t block_out[8][8];
        double ref_out[8][8];
        double ref_in[8][8];
        
        srand(42);
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                int val = rand() % 256;
                block_in[i][j] = val;
                ref_in[i][j] = val;
            }
        }
        
        dct2d_8x8(block_in, block_out);
        reference_dct2d(ref_in, ref_out);
        
        if (compare_results(block_out, ref_out)) {
            cout << "PASSED" << endl;
            tests_passed++;
        } else {
            cout << "FAILED" << endl;
        }
    }
    
    // Summary
    cout << "\n======================================" << endl;
    cout << "Test Summary" << endl;
    cout << "======================================" << endl;
    cout << "Passed: " << tests_passed << "/" << tests_total << endl;
    
    if (tests_passed == tests_total) {
        cout << "ALL TESTS PASSED!" << endl;
        return 0;
    } else {
        cout << "SOME TESTS FAILED!" << endl;
        return 1;
    }
}

