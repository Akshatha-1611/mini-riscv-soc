module cache_system (

    input clk,
    input rst,

    // CPU side
    input [31:0] cpu_addr,
    input [31:0] cpu_write_data,

    input cpu_read,
    input cpu_write,

    output [31:0] cpu_read_data,
    output cpu_ready

);

    // ============================================
    // CACHE ↔ MEMORY WIRES
    // ============================================

    wire [31:0] mem_addr;
    wire [31:0] mem_write_data;

    wire mem_read;
    wire mem_write;

    wire [31:0] mem_read_data;
    wire mem_ready;

    // ============================================
    // CACHE CONTROLLER
    // ============================================

    cache_controller cache (

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

    // ============================================
    // MAIN MEMORY
    // ============================================

    main_memory memory (

        .clk(clk),

        .addr(mem_addr),
        .write_data(mem_write_data),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .read_data(mem_read_data),
        .ready(mem_ready)

    );

endmodule