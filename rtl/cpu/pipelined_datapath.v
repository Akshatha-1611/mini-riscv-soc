module pipelined_datapath (

    input clk,
    input rst

);

    // =====================================================
    // PROGRAM COUNTER
    // =====================================================

    reg [31:0] pc;

    always @(posedge clk or posedge rst) begin

        if (rst)
            pc <= 0;

        else
            pc <= pc + 4;

    end

    // =====================================================
    // IF STAGE
    // =====================================================

    wire [31:0] instruction_if;

    instruction_memory instr_mem (

        .address(pc),
        .instruction(instruction_if)

    );

    // =====================================================
    // IF/ID PIPELINE REGISTER
    // =====================================================

    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;

    if_id if_id_reg (

        .clk(clk),
        .rst(rst),

        .write_enable(1'b1),

        .pc_in(pc),
        .instruction_in(instruction_if),

        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)

    );

    // =====================================================
    // ID STAGE
    // =====================================================

    wire [6:0] opcode_id;

    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rd_id;

    assign opcode_id = if_id_instruction[6:0];

    assign rd_id  = if_id_instruction[11:7];
    assign rs1_id = if_id_instruction[19:15];
    assign rs2_id = if_id_instruction[24:20];

    // Control signals
    wire reg_write_id;
    wire mem_read_id;
    wire mem_write_id;
    wire alu_src_id;
    wire branch_id;
    wire mem_to_reg_id;

    wire [2:0] alu_op_id;

    control_unit control (

        .opcode(opcode_id),

        .reg_write(reg_write_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),
        .alu_src(alu_src_id),
        .branch(branch_id),
        .mem_to_reg(mem_to_reg_id),

        .alu_op(alu_op_id)

    );

    // Register file
    wire [31:0] read_data1_id;
    wire [31:0] read_data2_id;

    // WB stage signals (forward declaration)
    wire reg_write_wb;
    wire [4:0] rd_wb;
    wire [31:0] writeback_data;

    register_file reg_file (

        .clk(clk),
        .rst(rst),

        .rs1(rs1_id),
        .rs2(rs2_id),

        .rd(rd_wb),
        .write_data(writeback_data),
        .reg_write(reg_write_wb),

        .read_data1(read_data1_id),
        .read_data2(read_data2_id)

    );

    // Immediate generator
    wire [31:0] imm_id;

    immediate_generator imm_gen (

        .instruction(if_id_instruction),
        .imm_out(imm_id)

    );

    // =====================================================
    // ID/EX PIPELINE REGISTER
    // =====================================================

    wire [31:0] id_ex_pc;

    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;

    wire [31:0] id_ex_imm;

    wire [4:0] id_ex_rd;

    wire id_ex_reg_write;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire id_ex_alu_src;
    wire id_ex_mem_to_reg;

    wire [2:0] id_ex_alu_op;

    id_ex id_ex_reg (

        .clk(clk),
        .rst(rst),

        .write_enable(1'b1),

        .pc_in(if_id_pc),

        .read_data1_in(read_data1_id),
        .read_data2_in(read_data2_id),

        .imm_in(imm_id),

        .rd_in(rd_id),

        .reg_write_in(reg_write_id),
        .mem_read_in(mem_read_id),
        .mem_write_in(mem_write_id),
        .alu_src_in(alu_src_id),
        .mem_to_reg_in(mem_to_reg_id),

        .alu_op_in(alu_op_id),

        .pc_out(id_ex_pc),

        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),

        .imm_out(id_ex_imm),

        .rd_out(id_ex_rd),

        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .alu_src_out(id_ex_alu_src),
        .mem_to_reg_out(id_ex_mem_to_reg),

        .alu_op_out(id_ex_alu_op)

    );

    // =====================================================
    // EX STAGE
    // =====================================================

    wire [31:0] alu_input_b_ex;

    wire [31:0] alu_result_ex;

    wire zero_ex;

    // ALU operand mux
    assign alu_input_b_ex =
            (id_ex_alu_src) ?
            id_ex_imm :
            id_ex_read_data2;

    alu alu_unit (

        .a(id_ex_read_data1),
        .b(alu_input_b_ex),

        .alu_sel(id_ex_alu_op),

        .result(alu_result_ex),
        .zero(zero_ex)

    );

    // =====================================================
    // EX/MEM PIPELINE REGISTER
    // =====================================================

    wire [31:0] ex_mem_alu_result;

    wire [31:0] ex_mem_read_data2;

    wire [4:0] ex_mem_rd;

    wire ex_mem_reg_write;
    wire ex_mem_mem_read;
    wire ex_mem_mem_write;
    wire ex_mem_mem_to_reg;

    ex_mem ex_mem_reg (

        .clk(clk),
        .rst(rst),

        .write_enable(1'b1),

        .alu_result_in(alu_result_ex),
        .read_data2_in(id_ex_read_data2),

        .rd_in(id_ex_rd),

        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_to_reg_in(id_ex_mem_to_reg),

        .alu_result_out(ex_mem_alu_result),
        .read_data2_out(ex_mem_read_data2),

        .rd_out(ex_mem_rd),

        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg)

    );

        // =====================================================
    // MEM STAGE
    // =====================================================

    wire [31:0] mem_read_data_mem;

    data_memory data_mem (

        .clk(clk),

        .mem_write(ex_mem_mem_write),
        .mem_read(ex_mem_mem_read),

        .address(ex_mem_alu_result),

        .write_data(ex_mem_read_data2),

        .read_data(mem_read_data_mem)

    );

    // =====================================================
    // MEM/WB PIPELINE REGISTER
    // =====================================================

    wire [31:0] mem_wb_mem_data;

    wire [31:0] mem_wb_alu_result;

    wire [4:0] mem_wb_rd;

    wire mem_wb_reg_write;
    wire mem_wb_mem_to_reg;

    mem_wb mem_wb_reg (

        .clk(clk),
        .rst(rst),

        .write_enable(1'b1),

        .mem_data_in(mem_read_data_mem),
        .alu_result_in(ex_mem_alu_result),

        .rd_in(ex_mem_rd),

        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),

        .mem_data_out(mem_wb_mem_data),
        .alu_result_out(mem_wb_alu_result),

        .rd_out(mem_wb_rd),

        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg)

    );
    // =====================================================
    // WB STAGE
    // =====================================================

    assign writeback_data =
            (mem_wb_mem_to_reg) ?
            mem_wb_mem_data :
            mem_wb_alu_result;

    assign reg_write_wb = mem_wb_reg_write;

    assign rd_wb = mem_wb_rd;
endmodule