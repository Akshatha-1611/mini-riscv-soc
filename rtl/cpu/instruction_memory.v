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

    memory[0] = 32'h00002083; // LW   x1, 0(x0)

    memory[1] = 32'h00108133; // ADD  x2, x1, x1

    memory[2] = 32'h002101B3; // ADD  x3, x2, x2

    memory[3] = 32'h00302023; // SW   x3, 0(x0)

    // LW x4, 0(x0)
    memory[4] = 32'h00002203;

end

assign instruction = memory[address[31:2]];

endmodule