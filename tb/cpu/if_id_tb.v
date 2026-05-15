`timescale 1ns/1ps

module if_id_tb;

    reg clk;
    reg rst;

    reg write_enable;

    reg [31:0] pc_in;
    reg [31:0] instruction_in;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;

    // Instantiate IF/ID register
    if_id uut (

        .clk(clk),
        .rst(rst),

        .write_enable(write_enable),

        .pc_in(pc_in),
        .instruction_in(instruction_in),

        .pc_out(pc_out),
        .instruction_out(instruction_out)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("if_id_tb.vcd");
        $dumpvars(0, if_id_tb);

        // Initialize
        clk = 0;
        rst = 1;
        write_enable = 1;

        pc_in = 0;
        instruction_in = 0;

        #10;
        rst = 0;

        // Cycle 1
        pc_in = 32'd0;
        instruction_in = 32'h00A00093;

        #10;

        // Cycle 2
        pc_in = 32'd4;
        instruction_in = 32'h01400113;

        #10;

        // Stall example
        write_enable = 0;

        pc_in = 32'd8;
        instruction_in = 32'h002081B3;

        #10;

        // Resume
        write_enable = 1;

        #10;

        $finish;

    end

endmodule