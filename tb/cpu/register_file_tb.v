`timescale 1ns/1ps

module register_file_tb;

    reg clk;
    reg rst;

    reg [4:0] rs1;
    reg [4:0] rs2;

    reg [4:0] rd;
    reg [31:0] write_data;
    reg reg_write;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Instantiate Register File
    register_file uut (

        .clk(clk),
        .rst(rst),

        .rs1(rs1),
        .rs2(rs2),

        .rd(rd),
        .write_data(write_data),
        .reg_write(reg_write),

        .read_data1(read_data1),
        .read_data2(read_data2)

    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin

        // Dump waveform
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);

        // Initialize
        clk = 0;
        rst = 1;

        rs1 = 0;
        rs2 = 0;

        rd = 0;
        write_data = 0;
        reg_write = 0;

        #10;
        rst = 0;

        // -------------------------
        // Write to x1
        // -------------------------
        rd = 5'd1;
        write_data = 32'd100;
        reg_write = 1;

        #10;

        // -------------------------
        // Write to x2
        // -------------------------
        rd = 5'd2;
        write_data = 32'd200;
        reg_write = 1;

        #10;

        // -------------------------
        // Read x1 and x2
        // -------------------------
        rs1 = 5'd1;
        rs2 = 5'd2;

        #10;

        // -------------------------
        // Attempt write to x0
        // -------------------------
        rd = 5'd0;
        write_data = 32'd999;
        reg_write = 1;

        #10;

        // Read x0
        rs1 = 5'd0;

        #10;

        $finish;

    end

endmodule