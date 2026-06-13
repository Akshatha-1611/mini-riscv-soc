// ============================================================
// Forwarding Unit
// Resolves RAW hazards by forwarding EX→EX and MEM→EX
// Forward A / Forward B encoding:
//   2'b00 = from register file (no forward)
//   2'b10 = forward from EX/MEM (previous result)
//   2'b01 = forward from MEM/WB (two-cycle-old result)
// ============================================================
`timescale 1ns/1ps

module forwarding_unit (
    // Current EX-stage source registers
    input  wire [4:0]  ex_rs1,
    input  wire [4:0]  ex_rs2,

    // EX/MEM pipeline register
    input  wire        ex_mem_reg_write,
    input  wire [4:0]  ex_mem_rd,

    // MEM/WB pipeline register
    input  wire        mem_wb_reg_write,
    input  wire [4:0]  mem_wb_rd,

    // Forward select outputs
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);

    always @(*) begin
        // ---- Forward A ----
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == ex_rs1))
            forward_a = 2'b10; // EX/MEM forward
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == ex_rs1))
            forward_a = 2'b01; // MEM/WB forward
        else
            forward_a = 2'b00; // No forward

        // ---- Forward B ----
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == ex_rs2))
            forward_b = 2'b10; // EX/MEM forward
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == ex_rs2))
            forward_b = 2'b01; // MEM/WB forward
        else
            forward_b = 2'b00; // No forward
    end

endmodule
