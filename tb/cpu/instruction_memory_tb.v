// ============================================================
// Instruction Memory Testbench
// ============================================================
`timescale 1ns/1ps
module instruction_memory_tb;
    reg        clk;
    reg [31:0] addr;
    wire[31:0] instr;

    integer pass_count=0, fail_count=0;

    // No hex file: memory starts as NOPs
    instruction_memory #(.MEM_FILE("")) dut(.clk(clk),.addr(addr),.instr(instr));

    always #5 clk=~clk;

    initial begin
        $dumpfile("sim/instruction_memory_tb.vcd"); $dumpvars(0, instruction_memory_tb);
        clk=0; addr=0;

        // Force some values for test
        dut.mem[0] = 32'h00500093; // ADDI x1,x0,5
        dut.mem[1] = 32'h00A00113; // ADDI x2,x0,10
        dut.mem[2] = 32'h002081B3; // ADD  x3,x1,x2

        @(negedge clk); addr=32'h00;
        @(posedge clk); #1;
        if (instr===32'h00500093) begin $display("PASS | fetch_instr0"); pass_count++; end
        else begin $display("FAIL | fetch_instr0 got=%h",instr); fail_count++; end

        @(negedge clk); addr=32'h04;
        @(posedge clk); #1;
        if (instr===32'h00A00113) begin $display("PASS | fetch_instr1"); pass_count++; end
        else begin $display("FAIL | fetch_instr1 got=%h",instr); fail_count++; end

        @(negedge clk); addr=32'h08;
        @(posedge clk); #1;
        if (instr===32'h002081B3) begin $display("PASS | fetch_instr2"); pass_count++; end
        else begin $display("FAIL | fetch_instr2 got=%h",instr); fail_count++; end

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
