`timescale 1ns/1ps

module forwarding_unit_tb;

    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;

    reg [4:0] ex_mem_rd;
    reg [4:0] mem_wb_rd;

    reg ex_mem_reg_write;
    reg mem_wb_reg_write;

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit uut (

        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),

        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),

        .forward_a(forward_a),
        .forward_b(forward_b)

    );

    initial begin

        $dumpfile("forwarding_unit_tb.vcd");
        $dumpvars(0, forwarding_unit_tb);

        // ==========================================
        // No forwarding
        // ==========================================

        id_ex_rs1 = 1;
        id_ex_rs2 = 2;

        ex_mem_rd = 3;
        mem_wb_rd = 4;

        ex_mem_reg_write = 1;
        mem_wb_reg_write = 1;

        #10;

        // ==========================================
        // EX forwarding
        // ==========================================

        ex_mem_rd = 1;

        #10;

        // ==========================================
        // MEM forwarding
        // ==========================================

        ex_mem_rd = 0;
        mem_wb_rd = 2;

        #10;

        $finish;

    end

endmodule