// ============================================================
// ALU Testbench
// Tests all ALU operations with directed and edge-case vectors
// Waveform: sim/waveforms/alu_tb.vcd
// ============================================================
`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    integer pass_count = 0, fail_count = 0;

    alu dut (
        .a       (a),
        .b       (b),
        .alu_ctrl(alu_ctrl),
        .result  (result),
        .zero    (zero)
    );

    // Dump waveforms
    initial begin
        $dumpfile("sim/alu_tb.vcd");
        $dumpvars(0, alu_tb);
    end

    // Helper task
    task check;
        input [31:0] expected;
        input [255:0] name;
        begin
            #1;
            if (result === expected) begin
                $display("PASS | %0s | a=%0d b=%0d | result=%0d", name, a, b, result);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %0s | a=%0d b=%0d | got=%0d expected=%0d",
                         name, a, b, result, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== ALU Testbench ===");
        a = 0; b = 0; alu_ctrl = 0;

        // ADD
        a = 32'd10;  b = 32'd20;  alu_ctrl = 4'b0000; check(32'd30, "ADD");
        a = 32'hFFFFFFFF; b = 32'd1; alu_ctrl = 4'b0000; check(32'd0, "ADD overflow");

        // SUB
        a = 32'd30;  b = 32'd10;  alu_ctrl = 4'b0001; check(32'd20, "SUB");
        a = 32'd0;   b = 32'd1;   alu_ctrl = 4'b0001; check(32'hFFFFFFFF, "SUB underflow");

        // AND
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_ctrl = 4'b0010;
        check(32'h0F000F00, "AND");

        // OR
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_ctrl = 4'b0011;
        check(32'hFF0FFF0F, "OR");

        // XOR
        a = 32'hAAAAAAAA; b = 32'h55555555; alu_ctrl = 4'b0100;
        check(32'hFFFFFFFF, "XOR");

        // SLL
        a = 32'd1;  b = 32'd4;  alu_ctrl = 4'b0101; check(32'd16, "SLL");
        a = 32'd1;  b = 32'd31; alu_ctrl = 4'b0101; check(32'h80000000, "SLL max");

        // SRL
        a = 32'h80000000; b = 32'd1;  alu_ctrl = 4'b0110; check(32'h40000000, "SRL");

        // SRA
        a = 32'h80000000; b = 32'd1;  alu_ctrl = 4'b0111; check(32'hC0000000, "SRA signed");

        // SLT
        a = 32'hFFFFFFFF; b = 32'd1;  alu_ctrl = 4'b1000; check(32'd1, "SLT -1<1");
        a = 32'd1;        b = 32'd0;  alu_ctrl = 4'b1000; check(32'd0, "SLT 1<0 false");

        // SLTU
        a = 32'hFFFFFFFF; b = 32'd1;  alu_ctrl = 4'b1001; check(32'd0, "SLTU large<1 false");
        a = 32'd0;        b = 32'd1;  alu_ctrl = 4'b1001; check(32'd1, "SLTU 0<1 true");

        // LUI pass
        a = 32'hABCD;  b = 32'hDEAD0000; alu_ctrl = 4'b1010; check(32'hDEAD0000, "LUI");

        // Zero flag
        a = 32'd5; b = 32'd5; alu_ctrl = 4'b0001;
        #1;
        if (zero !== 1'b1) $display("FAIL | ZERO flag not set when result=0");
        else begin $display("PASS | ZERO flag"); pass_count = pass_count + 1; end

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end

endmodule
