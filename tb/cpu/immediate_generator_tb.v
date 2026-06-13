// ============================================================
// Immediate Generator Testbench
// Verifies correct immediate extraction for all RISC-V formats
// ============================================================
`timescale 1ns/1ps
module immediate_generator_tb;
    reg  [31:0] instruction;
    wire [31:0] imm_out;

    integer pass_count = 0, fail_count = 0;

    immediate_generator dut(.instruction(instruction),.imm_out(imm_out));

    task check;
        input [31:0] exp;
        input [255:0] name;
        begin
            #1;
            if (imm_out===exp) begin $display("PASS | %0s | 0x%08h",name,imm_out); pass_count++; end
            else begin $display("FAIL | %0s | got=0x%08h exp=0x%08h",name,imm_out,exp); fail_count++; end
        end
    endtask

    initial begin
        $dumpfile("sim/immediate_generator_tb.vcd"); $dumpvars(0, immediate_generator_tb);

        // ADDI x1,x0,100  → I-type imm=100=0x64
        // instr[31:20]=0x064, rs1=0, funct3=000, rd=1, op=0010011
        instruction = 32'h06400093; check(32'd100, "ADDI_100");

        // ADDI with negative immediate: ADDI x1,x0,-4
        // imm=-4 = 0xFFC in 12-bit, sign extended → 0xFFFFFFFC
        instruction = 32'hFFC00093; check(32'hFFFFFFFC, "ADDI_neg4");

        // SW x1,8(x2)  → S-type: imm=8=0x008
        // imm[11:5]=0000000, imm[4:0]=01000
        instruction = 32'h00112423; check(32'd8, "SW_8");

        // BEQ x1,x2,+16  → B-type: imm=16
        // branch imm = 0x10 → {0,0,000001,0,000,0}
        instruction = 32'h00208863; check(32'd16, "BEQ_16");

        // LUI x5,0xDEAD0 → U-type
        instruction = 32'hDEAD02B7; check(32'hDEAD0000, "LUI");

        // JAL x1, +8 → J-type imm=8
        instruction = 32'h008000EF; check(32'd8, "JAL_8");

        // LW x3,4(x1)  → I-type imm=4
        instruction = 32'h00408183; check(32'd4, "LW_4");

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
