`timescale 1ns/1ps

module mem_wb_tb;

    reg clk;
    reg rst;

    reg write_enable;

    reg [31:0] mem_data_in;
    reg [31:0] alu_result_in;

    reg [4:0] rd_in;

    reg reg_write_in;
    reg mem_to_reg_in;

    wire [31:0] mem_data_out;
    wire [31:0] alu_result_out;

    wire [4:0] rd_out;

    wire reg_write_out;
    wire mem_to_reg_out;

    // Instantiate MEM/WB register
    mem_wb uut (

        .clk(clk),
        .rst(rst),

        .write_enable(write_enable),

        .mem_data_in(mem_data_in),
        .alu_result_in(alu_result_in),

        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .mem_to_reg_in(mem_to_reg_in),

        .mem_data_out(mem_data_out),
        .alu_result_out(alu_result_out),

        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .mem_to_reg_out(mem_to_reg_out)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("mem_wb_tb.vcd");
        $dumpvars(0, mem_wb_tb);

        // Initialize
        clk = 0;
        rst = 1;

        write_enable = 1;

        #10;
        rst = 0;

        // Test values
        mem_data_in = 32'd1234;
        alu_result_in = 32'd30;

        rd_in = 5'd4;

        reg_write_in = 1;
        mem_to_reg_in = 1;

        #10;

        // Stall test
        write_enable = 0;

        mem_data_in = 32'd9999;

        #10;

        $finish;

    end

endmodule