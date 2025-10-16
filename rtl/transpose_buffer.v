////////////////////////////////////////////////////////////////////////////////
// 8x8 Transpose Buffer using Dual-Port BRAM
// Ping-pong architecture for continuous streaming
// Write: row-major order
// Read: column-major order (transpose)
////////////////////////////////////////////////////////////////////////////////

module transpose_buffer #(
    parameter DATA_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst_n,
    
    // Write port (row-major)
    input  wire                         wr_en,
    input  wire [2:0]                   wr_row,
    input  wire [2:0]                   wr_col,
    input  wire signed [DATA_WIDTH-1:0] wr_data,
    input  wire                         wr_block_done,
    
    // Read port (column-major = transposed)
    input  wire                         rd_en,
    output reg  signed [DATA_WIDTH-1:0] rd_data,
    output reg                          rd_valid,
    output reg                          rd_block_done
);

    // Ping-pong buffers
    reg signed [DATA_WIDTH-1:0] buffer_A [0:63];
    reg signed [DATA_WIDTH-1:0] buffer_B [0:63];
    
    // Buffer selection
    reg active_wr_buf; // 0=A, 1=B
    reg active_rd_buf; // opposite of wr_buf when ready
    
    reg buf_A_ready;
    reg buf_B_ready;
    
    // Write logic
    wire [5:0] wr_addr = {wr_row, wr_col};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_wr_buf <= 0;
            buf_A_ready <= 0;
            buf_B_ready <= 0;
        end else begin
            if (wr_en) begin
                if (active_wr_buf == 0) begin
                    buffer_A[wr_addr] <= wr_data;
                end else begin
                    buffer_B[wr_addr] <= wr_data;
                end
            end
            
            if (wr_block_done) begin
                if (active_wr_buf == 0) begin
                    buf_A_ready <= 1;
                    active_wr_buf <= 1;
                end else begin
                    buf_B_ready <= 1;
                    active_wr_buf <= 0;
                end
            end
            
            // Clear ready flag when read starts
            if (rd_en && rd_col == 0 && rd_row == 0) begin
                if (active_rd_buf == 0)
                    buf_A_ready <= 0;
                else
                    buf_B_ready <= 0;
            end
        end
    end
    
    // Read logic (transpose: read column-major)
    reg [2:0] rd_row, rd_col;
    reg reading;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_row <= 0;
            rd_col <= 0;
            reading <= 0;
            rd_valid <= 0;
            rd_block_done <= 0;
            active_rd_buf <= 1; // opposite of initial wr_buf
        end else begin
            rd_block_done <= 0;
            
            // Start reading when buffer is ready
            if (!reading && ((active_rd_buf == 0 && buf_A_ready) || 
                           (active_rd_buf == 1 && buf_B_ready))) begin
                reading <= 1;
                rd_row <= 0;
                rd_col <= 0;
            end
            
            if (reading && rd_en) begin
                // Transpose addressing: swap row/col
                wire [5:0] rd_addr = {rd_col, rd_row};
                
                if (active_rd_buf == 0) begin
                    rd_data <= buffer_A[rd_addr];
                end else begin
                    rd_data <= buffer_B[rd_addr];
                end
                
                rd_valid <= 1;
                
                // Increment counters
                if (rd_row == 7) begin
                    rd_row <= 0;
                    if (rd_col == 7) begin
                        rd_col <= 0;
                        reading <= 0;
                        rd_block_done <= 1;
                        active_rd_buf <= ~active_rd_buf;
                    end else begin
                        rd_col <= rd_col + 1;
                    end
                end else begin
                    rd_row <= rd_row + 1;
                end
            end else begin
                rd_valid <= 0;
            end
        end
    end

endmodule

