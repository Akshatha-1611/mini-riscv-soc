`timescale 1ns/1ps

module ex_mem_tb;

    reg clk;
    reg rst;

    reg write_enable;

    reg [31:0] alu_result_in;
    reg [31:0] read_data2_in;

    reg [4:0] rd_in;

    reg reg_write_in;
    reg mem_read_in;
    reg mem_write_in;
    reg mem_to_reg_in;

    wire [31:0] alu_result_out;
    wire [31:0] read_data2_out;

    wire [4:0] rd_out;

    wire reg_write_out;
    wire mem_read_out;
    wire mem_write_out;
    wire mem_to_reg_out;

    // Instantiate EX/MEM register
    ex_mem uut (

        .clk(clk),
        .rst(rst),

        .write_enable(write_enable),

        .alu_result_in(alu_result_in),
        .read_data2_in(read_data2_in),

        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .mem_to_reg_in(mem_to_reg_in),

        .alu_result_out(alu_result_out),
        .read_data2_out(read_data2_out),

        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),
        .mem_to_reg_out(mem_to_reg_out)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("ex_mem_tb.vcd");
        $dumpvars(0, ex_mem_tb);

        // Initialize
        clk = 0;
        rst = 1;

        write_enable = 1;

        #10;
        rst = 0;

        // Test values
        alu_result_in = 32'd30;
        read_data2_in = 32'd20;

        rd_in = 5'd3;

        reg_write_in = 1;
        mem_read_in = 0;
        mem_write_in = 1;
        mem_to_reg_in = 0;

        #10;

        // Stall test
        write_enable = 0;

        alu_result_in = 32'd100;

        #10;

        $finish;

    end

endmodule