// ============================================================
// ID/EX Pipeline Register Testbench
// ============================================================
`timescale 1ns/1ps
module id_ex_tb;
    reg clk, rst_n, flush;
    reg reg_write_in, mem_to_reg_in, mem_read_in, mem_write_in;
    reg alu_src_in, branch_in, jump_in, jalr_in;
    reg [3:0] alu_ctrl_in;
    reg [2:0] mem_width_in;
    reg [31:0] pc_in, rs1_data_in, rs2_data_in, imm_in;
    reg [4:0] rs1_in, rs2_in, rd_in;

    wire reg_write_out, mem_to_reg_out, mem_read_out, mem_write_out;
    wire alu_src_out, branch_out, jump_out, jalr_out;
    wire [3:0] alu_ctrl_out;
    wire [2:0] mem_width_out;
    wire [31:0] pc_out, rs1_data_out, rs2_data_out, imm_out;
    wire [4:0] rs1_out, rs2_out, rd_out;

    integer pass_count = 0, fail_count = 0;

    id_ex dut(
        .clk(clk),.rst_n(rst_n),.flush(flush),
        .reg_write_in(reg_write_in),.mem_to_reg_in(mem_to_reg_in),
        .mem_read_in(mem_read_in),.mem_write_in(mem_write_in),
        .alu_src_in(alu_src_in),.branch_in(branch_in),
        .jump_in(jump_in),.jalr_in(jalr_in),
        .alu_ctrl_in(alu_ctrl_in),.mem_width_in(mem_width_in),
        .pc_in(pc_in),.rs1_data_in(rs1_data_in),.rs2_data_in(rs2_data_in),
        .imm_in(imm_in),.rs1_in(rs1_in),.rs2_in(rs2_in),.rd_in(rd_in),
        .reg_write_out(reg_write_out),.mem_to_reg_out(mem_to_reg_out),
        .mem_read_out(mem_read_out),.mem_write_out(mem_write_out),
        .alu_src_out(alu_src_out),.branch_out(branch_out),
        .jump_out(jump_out),.jalr_out(jalr_out),
        .alu_ctrl_out(alu_ctrl_out),.mem_width_out(mem_width_out),
        .pc_out(pc_out),.rs1_data_out(rs1_data_out),.rs2_data_out(rs2_data_out),
        .imm_out(imm_out),.rs1_out(rs1_out),.rs2_out(rs2_out),.rd_out(rd_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/id_ex_tb.vcd"); $dumpvars(0, id_ex_tb);
        clk=0; rst_n=0; flush=0;
        reg_write_in=0; mem_to_reg_in=0; mem_read_in=0; mem_write_in=0;
        alu_src_in=0; branch_in=0; jump_in=0; jalr_in=0;
        alu_ctrl_in=0; mem_width_in=0;
        pc_in=0; rs1_data_in=0; rs2_data_in=0; imm_in=0;
        rs1_in=0; rs2_in=0; rd_in=0;
        #12; rst_n=1;

        // Normal load
        @(negedge clk);
        reg_write_in=1; mem_read_in=1; alu_src_in=1;
        alu_ctrl_in=4'b0000; mem_width_in=3'b010;
        pc_in=32'h1000; rs1_data_in=32'hAAAA; rs2_data_in=32'hBBBB;
        imm_in=32'h4; rs1_in=5'd2; rs2_in=5'd3; rd_in=5'd5;
        @(posedge clk); #1;
        if (reg_write_out===1 && mem_read_out===1 && rd_out===5'd5)
            begin $display("PASS | id_ex_normal"); pass_count++; end
        else begin $display("FAIL | id_ex_normal"); fail_count++; end

        // Flush → all zeroed
        @(negedge clk); flush=1;
        @(posedge clk); #1;
        if (reg_write_out===0 && mem_read_out===0 && rd_out===5'd0)
            begin $display("PASS | id_ex_flush"); pass_count++; end
        else begin $display("FAIL | id_ex_flush"); fail_count++; end
        flush=0;

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
