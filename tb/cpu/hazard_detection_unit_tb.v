// ============================================================
// Hazard Detection Unit Testbench
// Tests: load-use stall, branch flush, jump flush
// Waveform: sim/hazard_detection_unit_tb.vcd
// ============================================================
`timescale 1ns/1ps

module hazard_detection_unit_tb;

    reg        id_ex_mem_read;
    reg  [4:0] id_ex_rd;
    reg  [4:0] if_id_rs1, if_id_rs2;
    reg        branch_taken, jump, jalr;

    wire       pc_write, if_id_write, id_ex_flush, if_id_flush;

    integer pass_count = 0, fail_count = 0;

    hazard_detection_unit dut (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd      (id_ex_rd),
        .if_id_rs1     (if_id_rs1),
        .if_id_rs2     (if_id_rs2),
        .branch_taken  (branch_taken),
        .jump          (jump),
        .jalr          (jalr),
        .pc_write      (pc_write),
        .if_id_write   (if_id_write),
        .id_ex_flush   (id_ex_flush),
        .if_id_flush   (if_id_flush)
    );

    initial begin
        $dumpfile("sim/hazard_detection_unit_tb.vcd");
        $dumpvars(0, hazard_detection_unit_tb);
    end

    task check1;
        input got, expected;
        input [255:0] name;
        begin
            if (got === expected) begin
                $display("PASS | %0s", name);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %0s | got=%b exp=%b", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Init
        id_ex_mem_read = 0; id_ex_rd = 0;
        if_id_rs1 = 0; if_id_rs2 = 0;
        branch_taken = 0; jump = 0; jalr = 0;
        #5;

        // ---- No hazard ----
        id_ex_mem_read = 0; id_ex_rd = 5'd1;
        if_id_rs1 = 5'd2; if_id_rs2 = 5'd3;
        branch_taken = 0; jump = 0; jalr = 0; #5;
        check1(pc_write,   1'b1, "no_hazard: pc_write=1");
        check1(if_id_write,1'b1, "no_hazard: if_id_write=1");
        check1(id_ex_flush,1'b0, "no_hazard: id_ex_flush=0");
        check1(if_id_flush,1'b0, "no_hazard: if_id_flush=0");

        // ---- Load-use via RS1 ----
        id_ex_mem_read = 1; id_ex_rd = 5'd3;
        if_id_rs1 = 5'd3; if_id_rs2 = 5'd5;
        branch_taken = 0; jump = 0; jalr = 0; #5;
        check1(pc_write,   1'b0, "load_use_rs1: pc_write=0");
        check1(if_id_write,1'b0, "load_use_rs1: if_id_write=0");
        check1(id_ex_flush,1'b1, "load_use_rs1: id_ex_flush=1");

        // ---- Load-use via RS2 ----
        id_ex_mem_read = 1; id_ex_rd = 5'd7;
        if_id_rs1 = 5'd1; if_id_rs2 = 5'd7;
        branch_taken = 0; jump = 0; jalr = 0; #5;
        check1(pc_write,   1'b0, "load_use_rs2: pc_write=0");
        check1(id_ex_flush,1'b1, "load_use_rs2: id_ex_flush=1");

        // ---- x0 load-use: no stall ----
        id_ex_mem_read = 1; id_ex_rd = 5'd0;
        if_id_rs1 = 5'd0; if_id_rs2 = 5'd0;
        branch_taken = 0; jump = 0; jalr = 0; #5;
        check1(pc_write,   1'b1, "x0_no_stall: pc_write=1");
        check1(id_ex_flush,1'b0, "x0_no_stall: id_ex_flush=0");

        // ---- Branch taken ----
        id_ex_mem_read = 0; id_ex_rd = 5'd0;
        if_id_rs1 = 5'd1; if_id_rs2 = 5'd2;
        branch_taken = 1; jump = 0; jalr = 0; #5;
        check1(if_id_flush,1'b1, "branch_taken: if_id_flush=1");
        check1(id_ex_flush,1'b1, "branch_taken: id_ex_flush=1");
        branch_taken = 0; #5;

        // ---- Jump (JAL) ----
        jump = 1; jalr = 0; #5;
        check1(if_id_flush,1'b1, "jump: if_id_flush=1");
        check1(id_ex_flush,1'b1, "jump: id_ex_flush=1");
        jump = 0; #5;

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end

endmodule
