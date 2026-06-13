// ============================================================
// CPU Top-Level
// Connects pipelined_datapath with instruction and data memories
// ============================================================
`timescale 1ns/1ps

module cpu_top #(
    parameter MEM_FILE = ""
)(
    input  wire        clk,
    input  wire        rst_n,
    // Debug outputs
    output wire [4:0]  wb_rd,
    output wire [31:0] wb_data,
    output wire        wb_we
);

    // Instruction memory interface
    wire [31:0] imem_addr, imem_data;

    // Data memory interface
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire        dmem_we, dmem_re;
    wire [2:0]  dmem_width;

    // Pipelined datapath
    pipelined_datapath u_datapath (
        .clk       (clk),
        .rst_n     (rst_n),
        .imem_addr (imem_addr),
        .imem_data (imem_data),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we   (dmem_we),
        .dmem_re   (dmem_re),
        .dmem_width(dmem_width),
        .dmem_rdata(dmem_rdata),
        .wb_rd     (wb_rd),
        .wb_data   (wb_data),
        .wb_we     (wb_we)
    );

    // Instruction memory
    instruction_memory #(.MEM_FILE(MEM_FILE)) u_imem (
        .clk  (clk),
        .addr (imem_addr),
        .instr(imem_data)
    );

    // Data memory
    data_memory u_dmem (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (dmem_addr),
        .write_data(dmem_wdata),
        .mem_read  (dmem_re),
        .mem_write (dmem_we),
        .width     (dmem_width),
        .read_data (dmem_rdata)
    );

endmodule
