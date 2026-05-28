module main_memory (

    input clk,

    input [31:0] addr,
    input [31:0] write_data,

    input mem_read,
    input mem_write,

    output reg [31:0] read_data,
    output reg ready

);

    // ============================================
    // SIMPLE MAIN MEMORY
    // ============================================

    reg [31:0] memory [0:255];

    integer i;

    initial begin

        for (i = 0; i < 256; i = i + 1)

            memory[i] = 0;

    end

    always @(posedge clk) begin

        ready <= 0;

        // ========================================
        // MEMORY READ
        // ========================================

        if (mem_read) begin

            read_data <= memory[addr[9:2]];

            ready <= 1;

        end

        // ========================================
        // MEMORY WRITE
        // ========================================

        if (mem_write) begin

            memory[addr[9:2]] <= write_data;

            ready <= 1;

        end

    end

endmodule