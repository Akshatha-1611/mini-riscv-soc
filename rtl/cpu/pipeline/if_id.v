// ============================================================
// IF/ID Pipeline Register
// ============================================================
`timescale 1ns/1ps

module if_id (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,    // 1 = insert NOP bubble
    input  wire        stall,    // 1 = hold current value
    // Inputs from IF stage
    input  wire [31:0] if_pc,
    input  wire [31:0] if_instr,
    // Outputs to ID stage
    output reg  [31:0] id_pc,
    output reg  [31:0] id_instr
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // NOP
        end else if (flush) begin
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // Flush → NOP
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
        // stall: hold previous values
    end

endmodule
