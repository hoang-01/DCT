////////////////////////////////////////////////////////////////////////////////
// 2D DCT-II Top Module (8x8 blocks)
// AXI4-Stream interface
// Pipeline: Row DCT -> Transpose -> Column DCT
// Throughput: 64 cycles per block (after initial latency)
////////////////////////////////////////////////////////////////////////////////

module dct2d_top #(
    parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = 16
)(
    input  wire                          clk,
    input  wire                          rst_n,
    
    // AXI4-Stream Slave (input pixels)
    input  wire                          s_axis_tvalid,
    output wire                          s_axis_tready,
    input  wire [INPUT_WIDTH-1:0]        s_axis_tdata,
    input  wire                          s_axis_tlast,  // last pixel of 8x8 block
    
    // AXI4-Stream Master (output DCT coefficients)
    output wire                          m_axis_tvalid,
    input  wire                          m_axis_tready,
    output wire [OUTPUT_WIDTH-1:0]       m_axis_tdata,
    output wire                          m_axis_tlast   // last coef of 8x8 block
);

    // State machine
    localparam IDLE = 0, ROW_INPUT = 1, ROW_PROCESS = 2, 
               TRANSPOSE = 3, COL_PROCESS = 4, OUTPUT = 5;
    reg [2:0] state;
    
    // Input counters
    reg [5:0] in_pixel_cnt;  // 0..63
    reg [2:0] in_row, in_col;
    
    // Row DCT signals
    wire                         row_dct_in_valid;
    wire signed [INPUT_WIDTH-1:0] row_dct_in_sample;
    wire [2:0]                   row_dct_in_index;
    wire                         row_dct_in_last;
    wire                         row_dct_out_valid;
    wire signed [OUTPUT_WIDTH-1:0] row_dct_out_coef;
    wire [2:0]                   row_dct_out_index;
    wire                         row_dct_out_last;
    
    // Transpose buffer signals
    reg                          trans_wr_en;
    reg [2:0]                    trans_wr_row, trans_wr_col;
    reg signed [OUTPUT_WIDTH-1:0] trans_wr_data;
    reg                          trans_wr_block_done;
    wire                         trans_rd_en;
    wire signed [OUTPUT_WIDTH-1:0] trans_rd_data;
    wire                         trans_rd_valid;
    wire                         trans_rd_block_done;
    
    // Column DCT signals
    wire                         col_dct_in_valid;
    wire signed [OUTPUT_WIDTH-1:0] col_dct_in_sample;
    wire [2:0]                   col_dct_in_index;
    wire                         col_dct_in_last;
    wire                         col_dct_out_valid;
    wire signed [OUTPUT_WIDTH-1:0] col_dct_out_coef;
    wire [2:0]                   col_dct_out_index;
    wire                         col_dct_out_last;
    
    // Input buffer for row processing
    reg signed [INPUT_WIDTH-1:0] input_buffer [0:7];
    reg [2:0] buf_cnt;
    reg row_process_req;
    reg [2:0] current_row;
    
    assign s_axis_tready = (state == ROW_INPUT) || (state == IDLE);
    
    // Input buffering and row DCT feeding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            in_pixel_cnt <= 0;
            in_row <= 0;
            in_col <= 0;
            buf_cnt <= 0;
            row_process_req <= 0;
            current_row <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        state <= ROW_INPUT;
                        in_pixel_cnt <= 1;
                        in_row <= 0;
                        in_col <= 1;
                        input_buffer[0] <= s_axis_tdata;
                        buf_cnt <= 1;
                    end
                end
                
                ROW_INPUT: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        input_buffer[buf_cnt] <= s_axis_tdata;
                        buf_cnt <= buf_cnt + 1;
                        in_pixel_cnt <= in_pixel_cnt + 1;
                        
                        // Track position
                        if (in_col == 7) begin
                            in_col <= 0;
                            in_row <= in_row + 1;
                            // Row complete, trigger processing
                            row_process_req <= 1;
                            state <= ROW_PROCESS;
                        end else begin
                            in_col <= in_col + 1;
                        end
                    end
                end
                
                ROW_PROCESS: begin
                    row_process_req <= 0;
                    // Wait for row DCT to complete
                    if (row_dct_out_valid && row_dct_out_last) begin
                        if (current_row == 7) begin
                            state <= TRANSPOSE;
                            current_row <= 0;
                        end else begin
                            current_row <= current_row + 1;
                            state <= ROW_INPUT;
                            buf_cnt <= 0;
                        end
                    end
                end
                
                TRANSPOSE: begin
                    if (trans_wr_block_done) begin
                        state <= COL_PROCESS;
                    end
                end
                
                COL_PROCESS: begin
                    if (col_dct_out_valid && col_dct_out_last) begin
                        state <= IDLE;
                        in_pixel_cnt <= 0;
                    end
                end
            endcase
        end
    end
    
    // Row DCT input generation
    reg [2:0] row_feed_cnt;
    reg row_feeding;
    
    assign row_dct_in_valid = row_feeding;
    assign row_dct_in_sample = input_buffer[row_feed_cnt];
    assign row_dct_in_index = row_feed_cnt;
    assign row_dct_in_last = (row_feed_cnt == 7);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_feeding <= 0;
            row_feed_cnt <= 0;
        end else begin
            if (row_process_req && !row_feeding) begin
                row_feeding <= 1;
                row_feed_cnt <= 0;
            end else if (row_feeding) begin
                if (row_feed_cnt == 7) begin
                    row_feeding <= 0;
                    row_feed_cnt <= 0;
                end else begin
                    row_feed_cnt <= row_feed_cnt + 1;
                end
            end
        end
    end
    
    // Transpose write logic
    reg [2:0] trans_row_cnt, trans_col_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trans_wr_en <= 0;
            trans_wr_row <= 0;
            trans_wr_col <= 0;
            trans_wr_block_done <= 0;
            trans_row_cnt <= 0;
            trans_col_cnt <= 0;
        end else begin
            trans_wr_block_done <= 0;
            
            if (row_dct_out_valid) begin
                trans_wr_en <= 1;
                trans_wr_data <= row_dct_out_coef;
                trans_wr_row <= trans_row_cnt;
                trans_wr_col <= row_dct_out_index;
                
                if (row_dct_out_last) begin
                    if (trans_row_cnt == 7) begin
                        trans_wr_block_done <= 1;
                        trans_row_cnt <= 0;
                    end else begin
                        trans_row_cnt <= trans_row_cnt + 1;
                    end
                end
            end else begin
                trans_wr_en <= 0;
            end
        end
    end
    
    // Column DCT input from transpose
    assign trans_rd_en = (state == COL_PROCESS) && !col_dct_in_valid;
    assign col_dct_in_valid = trans_rd_valid;
    assign col_dct_in_sample = trans_rd_data;
    
    reg [2:0] col_feed_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_feed_idx <= 0;
        end else begin
            if (trans_rd_valid) begin
                col_feed_idx <= col_feed_idx + 1;
            end
        end
    end
    
    assign col_dct_in_index = col_feed_idx;
    assign col_dct_in_last = (col_feed_idx == 7) && trans_rd_valid;
    
    // Output assignment
    assign m_axis_tvalid = col_dct_out_valid;
    assign m_axis_tdata = col_dct_out_coef;
    assign m_axis_tlast = col_dct_out_last;
    
    // Instantiate Row DCT
    dct1d_loeffler #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) row_dct (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(row_dct_in_valid),
        .in_sample(row_dct_in_sample),
        .in_index(row_dct_in_index),
        .in_last(row_dct_in_last),
        .out_valid(row_dct_out_valid),
        .out_coef(row_dct_out_coef),
        .out_index(row_dct_out_index),
        .out_last(row_dct_out_last)
    );
    
    // Instantiate Transpose Buffer
    transpose_buffer #(
        .DATA_WIDTH(OUTPUT_WIDTH)
    ) transpose (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(trans_wr_en),
        .wr_row(trans_wr_row),
        .wr_col(trans_wr_col),
        .wr_data(trans_wr_data),
        .wr_block_done(trans_wr_block_done),
        .rd_en(trans_rd_en),
        .rd_data(trans_rd_data),
        .rd_valid(trans_rd_valid),
        .rd_block_done(trans_rd_block_done)
    );
    
    // Instantiate Column DCT
    dct1d_loeffler #(
        .INPUT_WIDTH(OUTPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) col_dct (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(col_dct_in_valid),
        .in_sample(col_dct_in_sample),
        .in_index(col_dct_in_index),
        .in_last(col_dct_in_last),
        .out_valid(col_dct_out_valid),
        .out_coef(col_dct_out_coef),
        .out_index(col_dct_out_index),
        .out_last(col_dct_out_last)
    );

endmodule

