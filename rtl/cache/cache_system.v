// ============================================================
// Cache System — wraps cache_controller + main_memory
// No parameters needed: controller is fixed 4-set for sim
// ============================================================
`timescale 1ns/1ps

module cache_system (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_we,
    input  wire        cpu_re,
    output wire [31:0] cpu_rdata,
    output wire        cpu_ready,
    output wire        cpu_stall
);

    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire        mem_we, mem_re, mem_ready;

    cache_controller u_cache (
        .clk      (clk),       .rst_n    (rst_n),
        .cpu_addr (cpu_addr),  .cpu_wdata(cpu_wdata),
        .cpu_we   (cpu_we),    .cpu_re   (cpu_re),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .cpu_stall(cpu_stall),
        .mem_addr (mem_addr),  .mem_wdata(mem_wdata),
        .mem_we   (mem_we),    .mem_re   (mem_re),
        .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

    main_memory u_mem (
        .clk  (clk),  .rst_n(rst_n),
        .addr (mem_addr),  .wdata(mem_wdata),
        .we   (mem_we),    .re   (mem_re),
        .rdata(mem_rdata), .ready(mem_ready)
    );

endmodule