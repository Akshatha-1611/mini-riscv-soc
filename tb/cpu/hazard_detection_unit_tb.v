`timescale 1ns/1ps

module hazard_detection_unit_tb;

    reg id_ex_mem_read;

    reg [4:0] id_ex_rd;

    reg [4:0] if_id_rs1;
    reg [4:0] if_id_rs2;

    wire pc_write;
    wire if_id_write;
    wire control_mux_sel;

    hazard_detection_unit uut (

        .id_ex_mem_read(id_ex_mem_read),

        .id_ex_rd(id_ex_rd),

        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),

        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_mux_sel(control_mux_sel)

    );

    initial begin

        $dumpfile("hazard_detection_unit_tb.vcd");
        $dumpvars(0, hazard_detection_unit_tb);

        // ==========================================
        // No hazard
        // ==========================================

        id_ex_mem_read = 1;

        id_ex_rd = 5'd1;

        if_id_rs1 = 5'd2;
        if_id_rs2 = 5'd3;

        #10;

        // ==========================================
        // Hazard detected
        // ==========================================

        if_id_rs1 = 5'd1;

        #10;

        $finish;

    end

endmodule