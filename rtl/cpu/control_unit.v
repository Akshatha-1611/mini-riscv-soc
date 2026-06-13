// ============================================================
// Control Unit
// Decodes opcode to generate datapath control signals
// Supports: R-type, I-type, S-type, B-type, U-type, J-type
// ============================================================
`timescale 1ns/1ps

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,  // 1=memory, 0=ALU
    output reg        alu_src,     // 1=imm, 0=reg
    output reg        branch,
    output reg        jump,        // JAL
    output reg        jalr,        // JALR
    output reg  [3:0] alu_ctrl,
    output reg  [2:0] mem_width    // 000=byte,001=half,010=word
);

    // Opcodes (RISC-V spec)
    localparam OP_R      = 7'b0110011; // R-type
    localparam OP_I_ALU  = 7'b0010011; // I-type ALU (ADDI, etc.)
    localparam OP_LOAD   = 7'b0000011; // Load
    localparam OP_STORE  = 7'b0100011; // Store
    localparam OP_BRANCH = 7'b1100011; // Branch
    localparam OP_JAL    = 7'b1101111; // JAL
    localparam OP_JALR   = 7'b1100111; // JALR
    localparam OP_LUI    = 7'b0110111; // LUI
    localparam OP_AUIPC  = 7'b0010111; // AUIPC

    // ALU control encoding (matches alu.v)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    localparam ALU_LUI  = 4'b1010;
    localparam ALU_PASS = 4'b1011;

    always @(*) begin
        // Defaults (NOP-safe)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_ctrl   = ALU_ADD;
        mem_width  = funct3;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                case ({funct7[5], funct3})
                    4'b0000: alu_ctrl = ALU_ADD;
                    4'b1000: alu_ctrl = ALU_SUB;
                    4'b0001: alu_ctrl = ALU_SLL;
                    4'b0010: alu_ctrl = ALU_SLT;
                    4'b0011: alu_ctrl = ALU_SLTU;
                    4'b0100: alu_ctrl = ALU_XOR;
                    4'b0101: alu_ctrl = ALU_SRL;
                    4'b1101: alu_ctrl = ALU_SRA;
                    4'b0110: alu_ctrl = ALU_OR;
                    4'b0111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            OP_I_ALU: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;  // ADDI
                    3'b010: alu_ctrl = ALU_SLT;  // SLTI
                    3'b011: alu_ctrl = ALU_SLTU; // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;  // XORI
                    3'b110: alu_ctrl = ALU_OR;   // ORI
                    3'b111: alu_ctrl = ALU_AND;  // ANDI
                    3'b001: alu_ctrl = ALU_SLL;  // SLLI
                    3'b101: alu_ctrl = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                alu_ctrl   = ALU_ADD;
            end

            OP_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            OP_BRANCH: begin
                branch   = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = ALU_SUB;  // BEQ
                    3'b001: alu_ctrl = ALU_SUB;  // BNE
                    3'b100: alu_ctrl = ALU_SLT;  // BLT
                    3'b101: alu_ctrl = ALU_SLT;  // BGE
                    3'b110: alu_ctrl = ALU_SLTU; // BLTU
                    3'b111: alu_ctrl = ALU_SLTU; // BGEU
                    default: alu_ctrl = ALU_SUB;
                endcase
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_ctrl  = ALU_PASS;
            end

            OP_JALR: begin
                reg_write = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_LUI;
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            default: begin
                // NOP / unknown
            end
        endcase
    end

endmodule
