`timescale 1ns/1ps

module data_memory_tb;

    reg clk;

    reg mem_read;
    reg mem_write;

    reg [31:0] address;
    reg [31:0] write_data;

    wire [31:0] read_data;

    // Instantiate Data Memory
    data_memory uut (

        .clk(clk),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(address),
        .write_data(write_data),

        .read_data(read_data)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $dumpfile("data_memory_tb.vcd");
        $dumpvars(0, data_memory_tb);

        // Initialize
        clk = 0;

        mem_read = 0;
        mem_write = 0;

        address = 0;
        write_data = 0;

        // -------------------------
        // Write Data
        // -------------------------
        #10;

        mem_write = 1;
        address = 32'd0;
        write_data = 32'd1234;

        #10;

        mem_write = 0;

        // -------------------------
        // Read Data
        // -------------------------
        mem_read = 1;
        address = 32'd0;

        #10;

        mem_read = 0;

        #10;

        $finish;

    end

endmodule