// ============================================================
// Control Unit Testbench
// Tests all opcode → control signal mappings
// ============================================================
`timescale 1ns/1ps
module control_unit_tb;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire       reg_write, mem_read, mem_write, mem_to_reg;
    wire       alu_src, branch, jump, jalr;
    wire [3:0] alu_ctrl;
    wire [2:0] mem_width;

    integer pass_count = 0, fail_count = 0;

    control_unit dut(
        .opcode(opcode),.funct3(funct3),.funct7(funct7),
        .reg_write(reg_write),.mem_read(mem_read),.mem_write(mem_write),
        .mem_to_reg(mem_to_reg),.alu_src(alu_src),.branch(branch),
        .jump(jump),.jalr(jalr),.alu_ctrl(alu_ctrl),.mem_width(mem_width)
    );

    task chk;
        input got, exp;
        input [255:0] name;
        begin
            if (got===exp) begin $display("PASS | %0s=%b",name,got); pass_count++; end
            else begin $display("FAIL | %0s got=%b exp=%b",name,got,exp); fail_count++; end
        end
    endtask

    initial begin
        $dumpfile("sim/control_unit_tb.vcd"); $dumpvars(0, control_unit_tb);
        opcode=0; funct3=0; funct7=0; #5;

        // R-type ADD
        opcode=7'b0110011; funct3=3'b000; funct7=7'b0000000; #5;
        chk(reg_write,1,"R_ADD_reg_write");
        chk(mem_read,0,"R_ADD_mem_read");
        chk(mem_write,0,"R_ADD_mem_write");
        chk(alu_src,0,"R_ADD_alu_src");
        if (alu_ctrl===4'b0000) begin $display("PASS | R_ADD_alu_ctrl=ADD"); pass_count++; end
        else begin $display("FAIL | R_ADD_alu_ctrl=%b",alu_ctrl); fail_count++; end

        // I-type ADDI
        opcode=7'b0010011; funct3=3'b000; funct7=0; #5;
        chk(reg_write,1,"ADDI_reg_write");
        chk(alu_src,1,"ADDI_alu_src");
        chk(mem_read,0,"ADDI_mem_read");

        // LOAD
        opcode=7'b0000011; funct3=3'b010; #5;
        chk(reg_write,1,"LOAD_reg_write");
        chk(mem_read,1,"LOAD_mem_read");
        chk(mem_to_reg,1,"LOAD_mem_to_reg");
        chk(alu_src,1,"LOAD_alu_src");

        // STORE
        opcode=7'b0100011; funct3=3'b010; #5;
        chk(reg_write,0,"STORE_reg_write");
        chk(mem_write,1,"STORE_mem_write");
        chk(alu_src,1,"STORE_alu_src");

        // BRANCH
        opcode=7'b1100011; funct3=3'b000; #5;
        chk(branch,1,"BRANCH_branch");
        chk(reg_write,0,"BRANCH_reg_write");

        // JAL
        opcode=7'b1101111; funct3=0; #5;
        chk(jump,1,"JAL_jump");
        chk(reg_write,1,"JAL_reg_write");

        // LUI
        opcode=7'b0110111; #5;
        chk(reg_write,1,"LUI_reg_write");
        chk(alu_src,1,"LUI_alu_src");

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
