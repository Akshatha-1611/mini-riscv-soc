// ============================================================
// CDC FIFO — Dual-Clock, Gray-Code Pointer Synchronization
// Depth: 16 entries (power of 2 required for Gray code)
// Write port: wr_clk domain
// Read  port: rd_clk domain
// Safe Clock Domain Crossing via 2-FF synchronizer
// ============================================================
`timescale 1ns/1ps

module cdc_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16,   // Must be power of 2
    parameter PTR_WIDTH  = 4     // log2(DEPTH)
)(
    // Write domain
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  wr_en,
    output wire                  full,

    // Read domain
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    output reg  [DATA_WIDTH-1:0] rd_data,
    input  wire                  rd_en,
    output wire                  empty
);

    // ---- FIFO memory (dual-port, synchronous write, async read) ----
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

    // ---- Write domain pointers ----
    reg [PTR_WIDTH:0] wr_ptr_bin;  // Extra bit for full/empty
    reg [PTR_WIDTH:0] wr_ptr_gray;

    // ---- Read domain pointers ----
    reg [PTR_WIDTH:0] rd_ptr_bin;
    reg [PTR_WIDTH:0] rd_ptr_gray;

    // ---- 2-FF synchronizers ----
    // Sync wr_ptr_gray into rd_clk domain
    reg [PTR_WIDTH:0] wr_ptr_gray_s1_rd, wr_ptr_gray_s2_rd;
    // Sync rd_ptr_gray into wr_clk domain
    reg [PTR_WIDTH:0] rd_ptr_gray_s1_wr, rd_ptr_gray_s2_wr;

    // ---- Binary-to-Gray ----
    function [PTR_WIDTH:0] bin2gray;
        input [PTR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // ---- Write domain logic ----
    assign full = (wr_ptr_gray == {~rd_ptr_gray_s2_wr[PTR_WIDTH:PTR_WIDTH-1],
                                    rd_ptr_gray_s2_wr[PTR_WIDTH-2:0]});

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {(PTR_WIDTH+1){1'b0}};
            wr_ptr_gray <= {(PTR_WIDTH+1){1'b0}};
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr_bin[PTR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end

    // 2-FF sync: rd_ptr into wr_clk
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_s1_wr <= {(PTR_WIDTH+1){1'b0}};
            rd_ptr_gray_s2_wr <= {(PTR_WIDTH+1){1'b0}};
        end else begin
            rd_ptr_gray_s1_wr <= rd_ptr_gray;
            rd_ptr_gray_s2_wr <= rd_ptr_gray_s1_wr;
        end
    end

    // ---- Read domain logic ----
    assign empty = (rd_ptr_gray == wr_ptr_gray_s2_rd);

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {(PTR_WIDTH+1){1'b0}};
            rd_ptr_gray <= {(PTR_WIDTH+1){1'b0}};
            rd_data     <= {DATA_WIDTH{1'b0}};
        end else if (rd_en && !empty) begin
            rd_data     <= fifo_mem[rd_ptr_bin[PTR_WIDTH-1:0]];
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end

    // 2-FF sync: wr_ptr into rd_clk
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_s1_rd <= {(PTR_WIDTH+1){1'b0}};
            wr_ptr_gray_s2_rd <= {(PTR_WIDTH+1){1'b0}};
        end else begin
            wr_ptr_gray_s1_rd <= wr_ptr_gray;
            wr_ptr_gray_s2_rd <= wr_ptr_gray_s1_rd;
        end
    end

endmodule
