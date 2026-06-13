// ============================================================
// Immediate Generator
// Extracts and sign-extends immediates from RISC-V instruction formats:
// I-type, S-type, B-type, U-type, J-type
// ============================================================
`timescale 1ns/1ps

module immediate_generator (
    input  wire [31:0] instruction,
    output reg  [31:0] imm_out
);

    wire [6:0] opcode = instruction[6:0];

    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;

    always @(*) begin
        case (opcode)
            // I-type: [31:20] → sign extended
            OP_I_ALU, OP_LOAD, OP_JALR:
                imm_out = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: [31:25|11:7]
            OP_STORE:
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: [31|7|30:25|11:8] << 1
            OP_BRANCH:
                imm_out = {{19{instruction[31]}}, instruction[31],
                            instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-type: [31:12] << 12
            OP_LUI, OP_AUIPC:
                imm_out = {instruction[31:12], 12'b0};

            // J-type: [31|19:12|20|30:21] << 1
            OP_JAL:
                imm_out = {{11{instruction[31]}}, instruction[31],
                            instruction[19:12], instruction[20],
                            instruction[30:21], 1'b0};

            default:
                imm_out = 32'b0;
        endcase
    end

endmodule
