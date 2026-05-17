module control_unit (

    input [6:0] opcode,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,
    output reg branch,
    output reg mem_to_reg,

    output reg [2:0] alu_op

);

always @(*) begin

    // =====================================================
    // DEFAULT VALUES
    // =====================================================

    reg_write  = 0;
    mem_read   = 0;
    mem_write  = 0;
    alu_src    = 0;
    branch     = 0;
    mem_to_reg = 0;

    alu_op     = 3'b000;

    // =====================================================
    // OPCODE DECODE
    // =====================================================

    case (opcode)

        // -------------------------------------------------
        // R-TYPE
        // Example:
        // ADD x1, x2, x3
        // -------------------------------------------------

        7'b0110011: begin

            reg_write  = 1;

            mem_read   = 0;
            mem_write  = 0;

            alu_src    = 0;

            mem_to_reg = 0;

            branch     = 0;

            alu_op     = 3'b000;

        end

        // -------------------------------------------------
        // I-TYPE
        // Example:
        // ADDI x1, x0, 10
        // -------------------------------------------------

        7'b0010011: begin

            reg_write  = 1;

            mem_read   = 0;
            mem_write  = 0;

            alu_src    = 1;

            mem_to_reg = 0;

            branch     = 0;

            alu_op     = 3'b000;

        end

        // -------------------------------------------------
        // LOAD
        // Example:
        // LW x1, 0(x0)
        // -------------------------------------------------

        7'b0000011: begin

            reg_write  = 1;

            mem_read   = 1;
            mem_write  = 0;

            alu_src    = 1;

            mem_to_reg = 1;

            branch     = 0;

            alu_op     = 3'b000;

        end

        // -------------------------------------------------
        // STORE
        // Example:
        // SW x1, 0(x0)
        // -------------------------------------------------

        7'b0100011: begin

            reg_write  = 0;

            mem_read   = 0;
            mem_write  = 1;

            alu_src    = 1;

            mem_to_reg = 0;

            branch     = 0;

            alu_op     = 3'b000;

        end

        // -------------------------------------------------
        // BRANCH
        // Example:
        // BEQ x1, x2, label
        // -------------------------------------------------

        7'b1100011: begin

            reg_write  = 0;

            mem_read   = 0;
            mem_write  = 0;

            alu_src    = 0;

            mem_to_reg = 0;

            branch     = 1;

            alu_op     = 3'b001;

        end

        // -------------------------------------------------
        // DEFAULT
        // -------------------------------------------------

        default: begin

            reg_write  = 0;

            mem_read   = 0;
            mem_write  = 0;

            alu_src    = 0;

            mem_to_reg = 0;

            branch     = 0;

            alu_op     = 3'b000;

        end

    endcase

end

endmodule