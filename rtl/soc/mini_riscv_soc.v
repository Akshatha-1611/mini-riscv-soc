// ============================================================
// mini_riscv_soc — Top-Level SoC
// Architecture: CPU → Cache → CDC FIFO → Main Memory
// ============================================================
`timescale 1ns/1ps

module mini_riscv_soc #(
    parameter MEM_FILE = ""
)(
    input  wire cpu_clk,    // CPU / cache clock
    input  wire mem_clk,    // Memory bus clock (different domain)
    input  wire rst_n,
    // Debug
    output wire [4:0]  wb_rd,
    output wire [31:0] wb_data,
    output wire        wb_we
);

    // ---- CPU ↔ Cache ----
    wire [31:0] cpu_addr, cpu_wdata, cpu_rdata;
    wire        cpu_we, cpu_re, cpu_ready, cpu_stall;

    // ---- Cache ↔ FIFO (CPU clock) ----
    wire [31:0] cache_mem_addr, cache_mem_wdata;
    wire        cache_mem_we, cache_mem_re;
    // Pack address + data + we/re into FIFO write word
    // Simple scheme: 64-bit {addr[31:0], wdata[31:0]} or {addr,flags}
    // For simplicity we use two separate FIFOs: req and resp
    wire [63:0] req_wr_data;  // {addr, wdata}
    wire        req_wr_en;
    wire        req_full;
    wire [63:0] req_rd_data;
    wire        req_rd_en;
    wire        req_empty;

    wire [31:0] resp_wr_data; // rdata from memory
    wire        resp_wr_en;
    wire        resp_full;
    wire [31:0] resp_rd_data;
    wire        resp_rd_en;
    wire        resp_empty;

    // ---- CPU instantiation ----
    cpu_top #(.MEM_FILE(MEM_FILE)) u_cpu (
        .clk    (cpu_clk),
        .rst_n  (rst_n),
        .wb_rd  (wb_rd),
        .wb_data(wb_data),
        .wb_we  (wb_we)
    );

    // ---- Cache system ----
    cache_system u_cache (
        .clk      (cpu_clk),
        .rst_n    (rst_n),
        .cpu_addr (cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_we   (cpu_we),
        .cpu_re   (cpu_re),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .cpu_stall(cpu_stall)
    );

    // ---- Request CDC FIFO (CPU→MEM) ----
    cdc_fifo #(.DATA_WIDTH(64), .DEPTH(16), .PTR_WIDTH(4)) u_req_fifo (
        .wr_clk  (cpu_clk),
        .wr_rst_n(rst_n),
        .wr_data (req_wr_data),
        .wr_en   (req_wr_en),
        .full    (req_full),
        .rd_clk  (mem_clk),
        .rd_rst_n(rst_n),
        .rd_data (req_rd_data),
        .rd_en   (req_rd_en),
        .empty   (req_empty)
    );

    // ---- Response CDC FIFO (MEM→CPU) ----
    cdc_fifo #(.DATA_WIDTH(32), .DEPTH(16), .PTR_WIDTH(4)) u_resp_fifo (
        .wr_clk  (mem_clk),
        .wr_rst_n(rst_n),
        .wr_data (resp_wr_data),
        .wr_en   (resp_wr_en),
        .full    (resp_full),
        .rd_clk  (cpu_clk),
        .rd_rst_n(rst_n),
        .rd_data (resp_rd_data),
        .rd_en   (resp_rd_en),
        .empty   (resp_empty)
    );

    // ---- Main memory (mem_clk domain) ----
    wire [31:0] mem_rdata;
    wire        mem_ready;

    main_memory u_mem (
        .clk  (mem_clk),
        .rst_n(rst_n),
        .addr (req_rd_data[63:32]),
        .wdata(req_rd_data[31:0]),
        .we   (!req_empty && req_rd_data[63]), // MSB used as WE flag
        .re   (!req_empty && !req_rd_data[63]),
        .rdata(mem_rdata),
        .ready(mem_ready)
    );

    assign req_rd_en    = !req_empty && mem_ready;
    assign resp_wr_data = mem_rdata;
    assign resp_wr_en   = mem_ready && !req_rd_data[63]; // Only reads get response

endmodule
