////////////////////////////////////////////////////////////////////////////////
// SystemVerilog Testbench for DCT 2D Top Module
// Automated testing with golden reference comparison
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_dct2d_top;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz
    parameter INPUT_WIDTH = 8;
    parameter OUTPUT_WIDTH = 16;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // DUT signals
    logic                       s_axis_tvalid;
    logic                       s_axis_tready;
    logic [INPUT_WIDTH-1:0]     s_axis_tdata;
    logic                       s_axis_tlast;
    
    logic                       m_axis_tvalid;
    logic                       m_axis_tready;
    logic [OUTPUT_WIDTH-1:0]    m_axis_tdata;
    logic                       m_axis_tlast;
    
    // Test vectors
    `include "tb_vectors.vh"
    
    // Test control
    int test_num;
    int pixel_count;
    int coef_count;
    logic [7:0] current_input [0:63];
    logic signed [15:0] expected_output [0:63];
    logic signed [15:0] actual_output [0:63];
    
    // Statistics
    int total_tests;
    int passed_tests;
    int failed_tests;
    
    // DUT instantiation
    dct2d_top #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Load test vector task
    task load_test_vector(int test_id);
        case (test_id)
            0: begin
                current_input = test_input_0;
                expected_output = test_output_0;
            end
            1: begin
                current_input = test_input_1;
                expected_output = test_output_1;
            end
            2: begin
                current_input = test_input_2;
                expected_output = test_output_2;
            end
            3: begin
                current_input = test_input_3;
                expected_output = test_output_3;
            end
            4: begin
                current_input = test_input_4;
                expected_output = test_output_4;
            end
            5: begin
                current_input = test_input_5;
                expected_output = test_output_5;
            end
            6: begin
                current_input = test_input_6;
                expected_output = test_output_6;
            end
            7: begin
                current_input = test_input_7;
                expected_output = test_output_7;
            end
            8: begin
                current_input = test_input_8;
                expected_output = test_output_8;
            end
            9: begin
                current_input = test_input_9;
                expected_output = test_output_9;
            end
            10: begin
                current_input = test_input_10;
                expected_output = test_output_10;
            end
            default: begin
                $display("Invalid test ID: %0d", test_id);
            end
        endcase
    endtask
    
    // Send input block task
    task send_input_block();
        pixel_count = 0;
        
        while (pixel_count < 64) begin
            @(posedge clk);
            s_axis_tvalid <= 1'b1;
            s_axis_tdata <= current_input[pixel_count];
            s_axis_tlast <= (pixel_count == 63);
            
            if (s_axis_tready) begin
                pixel_count++;
            end
        end
        
        @(posedge clk);
        s_axis_tvalid <= 1'b0;
        s_axis_tlast <= 1'b0;
    endtask
    
    // Receive output block task
    task receive_output_block();
        coef_count = 0;
        m_axis_tready <= 1'b1;
        
        while (coef_count < 64) begin
            @(posedge clk);
            if (m_axis_tvalid && m_axis_tready) begin
                actual_output[coef_count] <= m_axis_tdata;
                coef_count++;
                
                if (m_axis_tlast && coef_count != 64) begin
                    $display("ERROR: tlast asserted at wrong position: %0d", coef_count);
                end
            end
        end
        
        m_axis_tready <= 1'b0;
    endtask
    
    // Compare results task
    task compare_results();
        int max_error;
        int error;
        longint sum_sq_error;
        real rmse;
        int mismatch_count;
        
        max_error = 0;
        sum_sq_error = 0;
        mismatch_count = 0;
        
        $display("\n--- Test %0d Results ---", test_num);
        
        for (int i = 0; i < 64; i++) begin
            error = $signed(actual_output[i]) - $signed(expected_output[i]);
            if (error < 0) error = -error;
            
            if (error > max_error) max_error = error;
            sum_sq_error += error * error;
            
            if (error > 100) begin // Tolerance threshold
                if (mismatch_count < 10) begin // Show first 10 errors
                    $display("  Mismatch at coef[%0d]: expected=%0d, actual=%0d, error=%0d",
                             i, $signed(expected_output[i]), $signed(actual_output[i]), error);
                end
                mismatch_count++;
            end
        end
        
        rmse = $sqrt(sum_sq_error / 64.0);
        
        $display("  Max Error: %0d", max_error);
        $display("  RMSE: %.2f", rmse);
        $display("  Mismatches (>100): %0d/64", mismatch_count);
        
        if (max_error <= 100 && mismatch_count == 0) begin
            $display("  Result: PASSED");
            passed_tests++;
        end else begin
            $display("  Result: FAILED");
            failed_tests++;
        end
        
        total_tests++;
    endtask
    
    // Main test sequence
    initial begin
        // Initialize
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tlast = 0;
        m_axis_tready = 0;
        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;
        
        // Reset pulse
        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);
        
        $display("\n================================================================================");
        $display("DCT 2D Top Module Testbench");
        $display("================================================================================");
        
        // Run all tests
        for (test_num = 0; test_num < NUM_TESTS; test_num++) begin
            $display("\n--- Running Test %0d ---", test_num);
            
            load_test_vector(test_num);
            
            fork
                send_input_block();
                receive_output_block();
            join
            
            compare_results();
            
            repeat (10) @(posedge clk);
        end
        
        // Final summary
        $display("\n================================================================================");
        $display("Test Summary");
        $display("================================================================================");
        $display("Total Tests: %0d", total_tests);
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", failed_tests);
        $display("Pass Rate: %.1f%%", (passed_tests * 100.0) / total_tests);
        $display("================================================================================\n");
        
        if (failed_tests == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000000; // 1ms timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end
    
    // Waveform dump (for GTKWave/Modelsim)
    initial begin
        $dumpfile("dct2d_tb.vcd");
        $dumpvars(0, tb_dct2d_top);
    end

endmodule

