// ============================================================
// MEM/WB Pipeline Register Testbench
// ============================================================
`timescale 1ns/1ps
module mem_wb_tb;
    reg clk, rst_n;
    reg reg_write_in, mem_to_reg_in;
    reg [31:0] mem_data_in, alu_result_in, pc_plus4_in;
    reg [4:0] rd_in;

    wire reg_write_out, mem_to_reg_out;
    wire [31:0] mem_data_out, alu_result_out, pc_plus4_out;
    wire [4:0] rd_out;

    integer pass_count = 0, fail_count = 0;

    mem_wb dut(
        .clk(clk),.rst_n(rst_n),
        .reg_write_in(reg_write_in),.mem_to_reg_in(mem_to_reg_in),
        .mem_data_in(mem_data_in),.alu_result_in(alu_result_in),
        .rd_in(rd_in),.pc_plus4_in(pc_plus4_in),
        .reg_write_out(reg_write_out),.mem_to_reg_out(mem_to_reg_out),
        .mem_data_out(mem_data_out),.alu_result_out(alu_result_out),
        .rd_out(rd_out),.pc_plus4_out(pc_plus4_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/mem_wb_tb.vcd"); $dumpvars(0, mem_wb_tb);
        clk=0; rst_n=0;
        reg_write_in=0; mem_to_reg_in=0; mem_data_in=0;
        alu_result_in=0; pc_plus4_in=0; rd_in=0;
        #12; rst_n=1;

        @(negedge clk);
        reg_write_in=1; mem_to_reg_in=1;
        mem_data_in=32'hCAFEBABE; alu_result_in=32'hDEADBEEF;
        rd_in=5'd12; pc_plus4_in=32'h2004;
        @(posedge clk); #1;
        if (reg_write_out===1 && mem_to_reg_out===1 &&
            mem_data_out===32'hCAFEBABE && rd_out===5'd12)
            begin $display("PASS | mem_wb_load"); pass_count++; end
        else begin $display("FAIL | mem_wb_load"); fail_count++; end

        @(negedge clk); mem_to_reg_in=0;
        @(posedge clk); #1;
        if (mem_to_reg_out===0)
            begin $display("PASS | mem_wb_alu_src"); pass_count++; end
        else begin $display("FAIL | mem_wb_alu_src"); fail_count++; end

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
