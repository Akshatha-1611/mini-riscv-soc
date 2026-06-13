// ============================================================
// EX/MEM Pipeline Register Testbench
// ============================================================
`timescale 1ns/1ps
module ex_mem_tb;
    reg clk, rst_n;
    reg reg_write_in, mem_to_reg_in, mem_read_in, mem_write_in;
    reg [2:0] mem_width_in;
    reg [31:0] alu_result_in, rs2_data_in, pc_plus4_in;
    reg [4:0] rd_in;

    wire reg_write_out, mem_to_reg_out, mem_read_out, mem_write_out;
    wire [2:0] mem_width_out;
    wire [31:0] alu_result_out, rs2_data_out, pc_plus4_out;
    wire [4:0] rd_out;

    integer pass_count = 0, fail_count = 0;

    ex_mem dut(
        .clk(clk),.rst_n(rst_n),
        .reg_write_in(reg_write_in),.mem_to_reg_in(mem_to_reg_in),
        .mem_read_in(mem_read_in),.mem_write_in(mem_write_in),
        .mem_width_in(mem_width_in),
        .alu_result_in(alu_result_in),.rs2_data_in(rs2_data_in),
        .rd_in(rd_in),.pc_plus4_in(pc_plus4_in),
        .reg_write_out(reg_write_out),.mem_to_reg_out(mem_to_reg_out),
        .mem_read_out(mem_read_out),.mem_write_out(mem_write_out),
        .mem_width_out(mem_width_out),
        .alu_result_out(alu_result_out),.rs2_data_out(rs2_data_out),
        .rd_out(rd_out),.pc_plus4_out(pc_plus4_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/ex_mem_tb.vcd"); $dumpvars(0, ex_mem_tb);
        clk=0; rst_n=0;
        reg_write_in=0; mem_to_reg_in=0; mem_read_in=0; mem_write_in=0;
        mem_width_in=0; alu_result_in=0; rs2_data_in=0; pc_plus4_in=0; rd_in=0;
        #12; rst_n=1;

        @(negedge clk);
        reg_write_in=1; mem_read_in=1; mem_to_reg_in=1;
        mem_width_in=3'b010; alu_result_in=32'hDEAD; rs2_data_in=32'hBEEF;
        rd_in=5'd8; pc_plus4_in=32'h1008;
        @(posedge clk); #1;
        if (alu_result_out===32'hDEAD && rd_out===5'd8 && mem_read_out===1 && reg_write_out===1)
            begin $display("PASS | ex_mem_pass"); pass_count++; end
        else begin $display("FAIL | ex_mem_pass"); fail_count++; end

        // Reset
        rst_n=0; #12; rst_n=1; #5;
        if (alu_result_out===32'h0 && rd_out===5'd0)
            begin $display("PASS | ex_mem_reset"); pass_count++; end
        else begin $display("FAIL | ex_mem_reset"); fail_count++; end

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
