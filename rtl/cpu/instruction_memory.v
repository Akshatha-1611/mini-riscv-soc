// ============================================================
// Instruction Memory (ROM)
// 1024 x 32-bit word-addressed, synchronous read
// Initialized with $readmemh for simulation
// ============================================================
`timescale 1ns/1ps

module instruction_memory #(
    parameter MEM_DEPTH = 1024,
    parameter MEM_FILE  = "program.hex"
)(
    input  wire        clk,
    input  wire [31:0] addr,      // Byte address
    output reg  [31:0] instr      // 32-bit instruction
);

    reg [31:0] mem [0:MEM_DEPTH-1];
    integer i;

    // Load program; ignore error if file not found (zeroes used)
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // NOP (ADDI x0,x0,0)
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, mem);
    end

    // Word-aligned synchronous read
    always @(posedge clk) begin
        instr <= mem[addr[31:2]]; // Drop bottom 2 bits (byte → word)
    end

endmodule
