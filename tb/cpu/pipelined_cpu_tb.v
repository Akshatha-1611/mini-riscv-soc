`timescale 1ns/1ps

module pipelined_cpu_tb;

    reg clk;
    reg rst;

    pipelined_datapath uut (

        .clk(clk),
        .rst(rst)

    );

    always #5 clk = ~clk;

    initial begin

        $dumpfile("pipelined_cpu_tb.vcd");
        $dumpvars(0, pipelined_cpu_tb);

        clk = 0;
        rst = 1;

        #10;
        rst = 0;

        #100;

        $finish;

    end

endmodule