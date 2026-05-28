`timescale 1ns/1ps

module pipelined_cpu_tb;

    reg clk;
    reg rst;
    reg cpu_ready;

    pipelined_datapath uut (

        .clk(clk),
        .rst(rst),
        .cpu_ready(cpu_ready)

    );

    always #5 clk = ~clk;

    initial begin

        cpu_ready = 1;

        $dumpfile("pipelined_cpu_tb.vcd");
        $dumpvars(0, pipelined_cpu_tb);

        clk = 0;
        rst = 1;

        #10;
        rst = 0;

        #30;

        cpu_ready = 0;

        #40;

        cpu_ready = 1;

        #40;

        $finish;

    end

endmodule