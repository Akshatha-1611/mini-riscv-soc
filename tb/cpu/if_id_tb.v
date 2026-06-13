// ============================================================
// IF/ID Pipeline Register Testbench
// Tests: normal flow, stall hold, flush to NOP
// ============================================================
`timescale 1ns/1ps

module if_id_tb;
    reg clk, rst_n, flush, stall;
    reg [31:0] if_pc, if_instr;
    wire [31:0] id_pc, id_instr;

    integer pass_count = 0, fail_count = 0;

    if_id dut(.clk(clk),.rst_n(rst_n),.flush(flush),.stall(stall),
              .if_pc(if_pc),.if_instr(if_instr),.id_pc(id_pc),.id_instr(id_instr));

    always #5 clk = ~clk;

    task check32;
        input [31:0] got, exp;
        input [255:0] name;
        begin
            if (got === exp) begin $display("PASS | %0s", name); pass_count++; end
            else begin $display("FAIL | %0s | got=%h exp=%h", name, got, exp); fail_count++; end
        end
    endtask

    initial begin
        $dumpfile("sim/if_id_tb.vcd"); $dumpvars(0, if_id_tb);
        clk=0; rst_n=0; flush=0; stall=0; if_pc=0; if_instr=0;
        #12; rst_n=1;

        // Normal pass-through
        @(negedge clk); if_pc=32'h100; if_instr=32'hABCDEF01;
        @(posedge clk); #1;
        check32(id_pc, 32'h100, "normal_pc");
        check32(id_instr, 32'hABCDEF01, "normal_instr");

        // Stall: hold
        @(negedge clk); stall=1; if_pc=32'h200; if_instr=32'hDEAD0000;
        @(posedge clk); #1;
        check32(id_pc, 32'h100, "stall_hold_pc");
        check32(id_instr, 32'hABCDEF01, "stall_hold_instr");
        stall=0;

        // Flush: NOP
        @(negedge clk); flush=1; if_pc=32'h300; if_instr=32'hFFFFFFFF;
        @(posedge clk); #1;
        check32(id_instr, 32'h00000013, "flush_nop");
        flush=0;

        // Reset: NOP
        rst_n=0; #12; rst_n=1; #5;
        check32(id_instr, 32'h00000013, "reset_nop");

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
