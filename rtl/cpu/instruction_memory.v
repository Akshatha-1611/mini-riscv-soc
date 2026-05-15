module instruction_memory (

    input  [31:0] address,

    output [31:0] instruction

);

    // 256 x 32-bit instruction memory
    reg [31:0] memory [0:255];

    // Word-aligned access
    assign instruction = memory[address[31:2]];

    initial begin

        // -------------------------
        // Example Program
        // -------------------------

        // ADDI x1, x0, 10
        memory[0] = 32'b00000000101000000000000010010011;

        // ADDI x2, x0, 20
        memory[1] = 32'b00000001010000000000000100010011;

        // ADD x3, x1, x2
        memory[2] = 32'b00000000001000001000000110110011;

        // SW x3, 0(x0)
        memory[3] = 32'b00000000001100000010000000100011;

        // LW x4, 0(x0)
        memory[4] = 32'b00000000000000000010001000000011;

    end

endmodule