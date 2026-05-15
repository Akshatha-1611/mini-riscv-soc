`timescale 1ns/1ps

module immediate_generator_tb;

    reg [31:0] instruction;

    wire [31:0] imm_out;

    // Instantiate module
    immediate_generator uut (

        .instruction(instruction),
        .imm_out(imm_out)

    );

    initial begin

        $dumpfile("immediate_generator_tb.vcd");
        $dumpvars(0, immediate_generator_tb);

        // -------------------------
        // I-Type Example
        // ADDI x1, x0, 10
        // -------------------------
        instruction = 32'b00000000101000000000000010010011;

        #10;

        // -------------------------
        // S-Type Example
        // SW
        // -------------------------
        instruction = 32'b00000000000100010010010000100011;

        #10;

        // -------------------------
        // B-Type Example
        // BEQ
        // -------------------------
        instruction = 32'b00000000000100001000010001100011;

        #10;

        $finish;

    end

endmodule