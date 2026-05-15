`timescale 1ns/1ps

module instruction_memory_tb;

    reg [31:0] address;

    wire [31:0] instruction;

    // Instantiate memory
    instruction_memory uut (

        .address(address),
        .instruction(instruction)

    );

    initial begin

        $dumpfile("instruction_memory_tb.vcd");
        $dumpvars(0, instruction_memory_tb);

        // Instruction 0
        address = 32'd0;
        #10;

        // Instruction 1
        address = 32'd4;
        #10;

        // Instruction 2
        address = 32'd8;
        #10;

        // Instruction 3
        address = 32'd12;
        #10;

        // Instruction 4
        address = 32'd16;
        #10;

        $finish;

    end

endmodule