`timescale 1ns/1ps

module cache_controller_tb;

reg clk;
reg rst;

reg [31:0] cpu_addr;
reg [31:0] cpu_write_data;

reg cpu_read;
reg cpu_write;

wire [31:0] cpu_read_data;
wire cpu_ready;

wire [31:0] mem_addr;
wire [31:0] mem_write_data;

wire mem_read;
wire mem_write;

reg [31:0] mem_read_data;
reg mem_ready;

cache_controller uut (

    .clk(clk),
    .rst(rst),

    .cpu_addr(cpu_addr),
    .cpu_write_data(cpu_write_data),

    .cpu_read(cpu_read),
    .cpu_write(cpu_write),

    .cpu_read_data(cpu_read_data),
    .cpu_ready(cpu_ready),

    .mem_addr(mem_addr),
    .mem_write_data(mem_write_data),

    .mem_read(mem_read),
    .mem_write(mem_write),

    .mem_read_data(mem_read_data),
    .mem_ready(mem_ready)

);

// Clock generation
always #5 clk = ~clk;

initial begin

    $dumpfile("cache_controller_tb.vcd");
    $dumpvars(0, cache_controller_tb);

    clk = 0;
    rst = 1;

    cpu_addr = 0;
    cpu_write_data = 0;

    cpu_read = 0;
    cpu_write = 0;

    mem_read_data = 0;
    mem_ready = 0;

    #10;
    rst = 0;

    // ==========================================
    // Manually preload cache
    // ==========================================

    uut.valid_array[0][0] = 1;

    uut.tag_array[0][0] = 26'h0;

    uut.data_array[0][0] = 32'hDEADBEEF;

    // ==========================================
    // CPU READ HIT TEST
    // ==========================================

    cpu_addr = 32'h00000000;

    cpu_read = 1;

    #10;

    cpu_read = 0;

    #20;

    // ==========================================
    // CACHE MISS TEST
    // ==========================================

    cpu_addr = 32'h00000040;

    cpu_read = 1;

    #10;

    // Simulate memory response
    mem_ready = 1;

    mem_read_data = 32'hCAFEBABE;

    #10;

    mem_ready = 0;

    cpu_read = 0;

    #30;

    // ==========================================
    // CACHE WRITE HIT TEST
    // ==========================================

    cpu_addr = 32'h00000000;

    cpu_write_data = 32'h12345678;

    cpu_write = 1;

    #10;

    cpu_write = 0;

    #20;
    // ==========================================
    // DIRTY EVICTION TEST
    // ==========================================

    // Make existing line dirty
    uut.dirty_array[0][0] = 1;
    uut.lru[0] = 0;

    uut.tag_array[0][0] = 26'h0;

    uut.data_array[0][0] = 32'hAAAAAAAA;

    // Access conflicting address
    cpu_addr = 32'h00000100;

    cpu_read = 1;

    #10;

    // Memory accepts write-back
    mem_ready = 1;

    #10;

    // Memory returns new line
    mem_read_data = 32'hBBBBBBBB;

    #10;

    mem_ready = 0;

    cpu_read = 0;

    #30;    
    $finish;

end

endmodule