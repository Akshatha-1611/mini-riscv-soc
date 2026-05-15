module datapath (

    input clk,
    input rst

);

    // -------------------------
    // Program Counter
    // -------------------------
    reg [31:0] pc;

    wire [31:0] instruction;

    // -------------------------
    // Instruction Fields
    // -------------------------
    wire [6:0] opcode;

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;

    assign opcode = instruction[6:0];

    assign rd  = instruction[11:7];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];

    // -------------------------
    // Control Signals
    // -------------------------
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire branch;
    wire mem_to_reg;

    wire [2:0] alu_op;

    // -------------------------
    // Register File Signals
    // -------------------------
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // -------------------------
    // Immediate
    // -------------------------
    wire [31:0] imm_out;

    // -------------------------
    // ALU
    // -------------------------
    wire [31:0] alu_input_b;
    wire [31:0] alu_result;

    wire zero;

    // -------------------------
    // Data Memory
    // -------------------------
    wire [31:0] mem_data;

    // -------------------------
    // Writeback
    // -------------------------
    wire [31:0] writeback_data;

    // =====================================================
    // Module Instantiations
    // =====================================================

    instruction_memory instr_mem (

        .address(pc),
        .instruction(instruction)

    );

    control_unit control (

        .opcode(opcode),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .mem_to_reg(mem_to_reg),

        .alu_op(alu_op)

    );

    register_file reg_file (

        .clk(clk),
        .rst(rst),

        .rs1(rs1),
        .rs2(rs2),

        .rd(rd),
        .write_data(writeback_data),
        .reg_write(reg_write),

        .read_data1(read_data1),
        .read_data2(read_data2)

    );

    immediate_generator imm_gen (

        .instruction(instruction),
        .imm_out(imm_out)

    );

    // ALU input mux
    assign alu_input_b = (alu_src) ? imm_out : read_data2;

    alu alu_unit (

        .a(read_data1),
        .b(alu_input_b),
        .alu_sel(alu_op),

        .result(alu_result),
        .zero(zero)

    );

    data_memory data_mem (

        .clk(clk),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(alu_result),
        .write_data(read_data2),

        .read_data(mem_data)

    );

    // Writeback mux
    assign writeback_data =
            (mem_to_reg) ? mem_data : alu_result;

    // =====================================================
    // Program Counter Logic
    // =====================================================

    always @(posedge clk or posedge rst) begin

        if (rst)
            pc <= 32'b0;

        else begin

            // Simple branch handling
            if (branch && zero)
                pc <= pc + imm_out;

            else
                pc <= pc + 4;

        end

    end

endmodule