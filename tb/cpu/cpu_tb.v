`timescale 1ns/1ps

module cpu_tb;

    reg clk;
    reg rst;

    // Instantiate datapath
    datapath uut (

        .clk(clk),
        .rst(rst)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        // Initialize
        clk = 0;
        rst = 1;

        #10;
        rst = 0;

        // Run CPU
        #100;

        $finish;

    end

endmodule