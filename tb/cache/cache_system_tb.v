`timescale 1ns/1ps

module cache_system_tb;

    reg clk;
    reg rst;

    reg [31:0] cpu_addr;
    reg [31:0] cpu_write_data;

    reg cpu_read;
    reg cpu_write;

    wire [31:0] cpu_read_data;
    wire cpu_ready;

    cache_system uut (

        .clk(clk),
        .rst(rst),

        .cpu_addr(cpu_addr),
        .cpu_write_data(cpu_write_data),

        .cpu_read(cpu_read),
        .cpu_write(cpu_write),

        .cpu_read_data(cpu_read_data),
        .cpu_ready(cpu_ready)

    );

    always #5 clk = ~clk;

    initial begin

        $dumpfile("cache_system_tb.vcd");
        $dumpvars(0, cache_system_tb);

        clk = 0;
        rst = 1;

        cpu_addr = 0;
        cpu_write_data = 0;

        cpu_read = 0;
        cpu_write = 0;

        #10;
        rst = 0;

        // ========================================
        // PRELOAD MEMORY
        // ========================================

        uut.memory.memory[0] = 32'h11111111;
        uut.memory.memory[1] = 32'h22222222;

        // ========================================
        // CACHE MISS → MEMORY FETCH
        // ========================================

        cpu_addr = 32'h00000000;
        cpu_read = 1;

        #20;

        cpu_read = 0;

        #30;

        // ========================================
        // CACHE HIT
        // ========================================

        cpu_addr = 32'h00000000;
        cpu_read = 1;

        #10;

        cpu_read = 0;

        #20;

        $finish;

    end

endmodule