`timescale 1ns/1ps

module id_ex_tb;

    reg clk;
    reg rst;

    reg write_enable;

    reg [31:0] pc_in;
    reg [31:0] read_data1_in;
    reg [31:0] read_data2_in;
    reg [31:0] imm_in;

    reg [4:0] rd_in;

    reg reg_write_in;
    reg mem_read_in;
    reg mem_write_in;
    reg alu_src_in;
    reg mem_to_reg_in;

    reg [2:0] alu_op_in;

    wire [31:0] pc_out;
    wire [31:0] read_data1_out;
    wire [31:0] read_data2_out;
    wire [31:0] imm_out;

    wire [4:0] rd_out;

    wire reg_write_out;
    wire mem_read_out;
    wire mem_write_out;
    wire alu_src_out;
    wire mem_to_reg_out;

    wire [2:0] alu_op_out;

    // Instantiate ID/EX register
    id_ex uut (

        .clk(clk),
        .rst(rst),

        .write_enable(write_enable),

        .pc_in(pc_in),
        .read_data1_in(read_data1_in),
        .read_data2_in(read_data2_in),
        .imm_in(imm_in),

        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .alu_src_in(alu_src_in),
        .mem_to_reg_in(mem_to_reg_in),

        .alu_op_in(alu_op_in),

        .pc_out(pc_out),
        .read_data1_out(read_data1_out),
        .read_data2_out(read_data2_out),
        .imm_out(imm_out),

        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),
        .alu_src_out(alu_src_out),
        .mem_to_reg_out(mem_to_reg_out),

        .alu_op_out(alu_op_out)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("id_ex_tb.vcd");
        $dumpvars(0, id_ex_tb);

        // Initialize
        clk = 0;
        rst = 1;

        write_enable = 1;

        #10;
        rst = 0;

        // Test values
        pc_in = 32'd4;

        read_data1_in = 32'd10;
        read_data2_in = 32'd20;

        imm_in = 32'd100;

        rd_in = 5'd3;

        reg_write_in = 1;
        mem_read_in = 0;
        mem_write_in = 0;
        alu_src_in = 1;
        mem_to_reg_in = 0;

        alu_op_in = 3'b000;

        #10;

        // Stall example
        write_enable = 0;

        pc_in = 32'd8;

        #10;

        $finish;

    end

endmodule