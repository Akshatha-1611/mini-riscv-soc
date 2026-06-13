// ============================================================
// Forwarding Unit Testbench
// Tests: no-forward, EX/MEM forward, MEM/WB forward, priority
// Waveform: sim/forwarding_unit_tb.vcd
// ============================================================
`timescale 1ns/1ps

module forwarding_unit_tb;

    reg  [4:0] ex_rs1, ex_rs2;
    reg        ex_mem_reg_write;
    reg  [4:0] ex_mem_rd;
    reg        mem_wb_reg_write;
    reg  [4:0] mem_wb_rd;

    wire [1:0] forward_a, forward_b;

    integer pass_count = 0, fail_count = 0;

    forwarding_unit dut (
        .ex_rs1          (ex_rs1),
        .ex_rs2          (ex_rs2),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd       (ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd       (mem_wb_rd),
        .forward_a       (forward_a),
        .forward_b       (forward_b)
    );

    initial begin
        $dumpfile("sim/forwarding_unit_tb.vcd");
        $dumpvars(0, forwarding_unit_tb);
    end

    task check2;
        input [1:0] got, expected;
        input [255:0] name;
        begin
            if (got === expected) begin
                $display("PASS | %0s | %2b", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %0s | got=%2b exp=%2b", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // No forwarding
        ex_rs1 = 5'd1; ex_rs2 = 5'd2;
        ex_mem_reg_write = 0; ex_mem_rd = 5'd3;
        mem_wb_reg_write = 0; mem_wb_rd = 5'd4;
        #5;
        check2(forward_a, 2'b00, "no_fwd_A");
        check2(forward_b, 2'b00, "no_fwd_B");

        // EX/MEM forward A
        ex_mem_reg_write = 1; ex_mem_rd = 5'd1;
        mem_wb_reg_write = 0; mem_wb_rd = 5'd1;
        #5;
        check2(forward_a, 2'b10, "ex_mem_fwd_A");

        // EX/MEM forward B
        ex_rs1 = 5'd5;
        ex_mem_rd = 5'd2; #5;
        check2(forward_b, 2'b10, "ex_mem_fwd_B");

        // MEM/WB forward A (no EX/MEM match)
        ex_rs1 = 5'd3; ex_rs2 = 5'd4;
        ex_mem_reg_write = 1; ex_mem_rd = 5'd9;
        mem_wb_reg_write = 1; mem_wb_rd = 5'd3;
        #5;
        check2(forward_a, 2'b01, "mem_wb_fwd_A");

        // Priority: EX/MEM wins over MEM/WB
        ex_rs1 = 5'd5;
        ex_mem_reg_write = 1; ex_mem_rd = 5'd5;
        mem_wb_reg_write = 1; mem_wb_rd = 5'd5;
        #5;
        check2(forward_a, 2'b10, "priority_ex_mem_over_wb_A");

        // x0 never forwarded
        ex_rs1 = 5'd0;
        ex_mem_reg_write = 1; ex_mem_rd = 5'd0;
        mem_wb_reg_write = 1; mem_wb_rd = 5'd0;
        #5;
        check2(forward_a, 2'b00, "x0_no_forward_A");

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end

endmodule
