module instruction_memory (

    input  [31:0] address,
    output [31:0] instruction

);

reg [31:0] memory [0:255];

integer i;

initial begin

    // Initialize all memory locations to zero
    for (i = 0; i < 256; i = i + 1)
        memory[i] = 32'b0;

    // Sample RISC-V program

    // ADDI x1, x0, 10
    memory[0] = 32'h00A00093;

    // ADDI x2, x0, 20
    memory[1] = 32'h01400113;

    // ADD x3, x1, x2
    memory[2] = 32'h002081B3;

    // SW x3, 0(x0)
    memory[3] = 32'h00302023;

    // LW x4, 0(x0)
    memory[4] = 32'h00002203;

end

assign instruction = memory[address[31:2]];

endmodule