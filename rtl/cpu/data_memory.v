module data_memory (

    input clk,

    input mem_read,
    input mem_write,

    input [31:0] address,
    input [31:0] write_data,

    output [31:0] read_data

);

    // 256 x 32-bit memory
    reg [31:0] memory [0:255];

    // -------------------------
    // Combinational Read
    // -------------------------
    assign read_data = (mem_read) ?
                       memory[address[31:2]] :
                       32'b0;

    // -------------------------
    // Synchronous Write
    // -------------------------
    always @(posedge clk) begin

        if (mem_write)
            memory[address[31:2]] <= write_data;

    end

endmodule