`timescale 1ns/1ps

module control_unit_tb;

    reg [6:0] opcode;

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire branch;
    wire mem_to_reg;

    wire [2:0] alu_op;

    // Instantiate Control Unit
    control_unit uut (

        .opcode(opcode),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .mem_to_reg(mem_to_reg),

        .alu_op(alu_op)

    );

    initial begin

        $dumpfile("control_unit_tb.vcd");
        $dumpvars(0, control_unit_tb);

        // R-Type
        opcode = 7'b0110011;
        #10;

        // I-Type
        opcode = 7'b0010011;
        #10;

        // LOAD
        opcode = 7'b0000011;
        #10;

        // STORE
        opcode = 7'b0100011;
        #10;

        // BRANCH
        opcode = 7'b1100011;
        #10;

        $finish;

    end

endmodule