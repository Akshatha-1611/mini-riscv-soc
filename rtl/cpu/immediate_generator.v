module immediate_generator (

    input [31:0] instruction,

    output reg [31:0] imm_out

);

    wire [6:0] opcode;

    assign opcode = instruction[6:0];

    always @(*) begin

        case (opcode)

            // -------------------------
            // I-Type (ADDI, LW)
            // imm[11:0] = instruction[31:20]
            // -------------------------
            7'b0010011,
            7'b0000011: begin

                imm_out = {{20{instruction[31]}}, instruction[31:20]};

            end

            // -------------------------
            // S-Type (SW)
            // imm[11:5] = instruction[31:25]
            // imm[4:0]  = instruction[11:7]
            // -------------------------
            7'b0100011: begin

                imm_out = {{20{instruction[31]}},
                           instruction[31:25],
                           instruction[11:7]};

            end

            // -------------------------
            // B-Type (BEQ)
            // -------------------------
            7'b1100011: begin

                imm_out = {{19{instruction[31]}},
                           instruction[31],
                           instruction[7],
                           instruction[30:25],
                           instruction[11:8],
                           1'b0};

            end

            default: begin

                imm_out = 32'b0;

            end

        endcase

    end

endmodule