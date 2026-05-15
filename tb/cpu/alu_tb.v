`timescale 1ns/1ps

module alu_tb;

    // Inputs
    reg [31:0] a;
    reg [31:0] b;
    reg [2:0] alu_sel;

    // Outputs
    wire [31:0] result;
    wire zero;

    // Instantiate ALU
    alu uut (

        .a(a),
        .b(b),
        .alu_sel(alu_sel),
        .result(result),
        .zero(zero)

    );

    initial begin

        // Dump waveform
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // -------------------------
        // ADD Test
        // -------------------------
        a = 10;
        b = 20;
        alu_sel = 3'b000;

        #10;

        // -------------------------
        // SUB Test
        // -------------------------
        a = 30;
        b = 10;
        alu_sel = 3'b001;

        #10;

        // -------------------------
        // AND Test
        // -------------------------
        a = 15;
        b = 7;
        alu_sel = 3'b010;

        #10;

        // -------------------------
        // OR Test
        // -------------------------
        a = 15;
        b = 7;
        alu_sel = 3'b011;

        #10;

        // -------------------------
        // XOR Test
        // -------------------------
        a = 15;
        b = 7;
        alu_sel = 3'b100;

        #10;

        // -------------------------
        // ZERO FLAG Test
        // -------------------------
        a = 20;
        b = 20;
        alu_sel = 3'b001;

        #10;

        $finish;

    end

endmodule