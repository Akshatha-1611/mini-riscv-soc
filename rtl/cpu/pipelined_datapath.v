module pipelined_datapath (

    input clk,
    input rst,
    input cpu_ready

);

    // =====================================================
    // PROGRAM COUNTER
    // =====================================================

    reg [31:0] pc;

    wire pipeline_stall;

    // Combined stall logic
    wire final_pc_write;
    wire final_if_id_write;

    assign pipeline_stall = ~cpu_ready;

    assign final_pc_write =
            pc_write && ~pipeline_stall;

    assign final_if_id_write =
            if_id_write && ~pipeline_stall;

    always @(posedge clk or posedge rst) begin

        if (rst)

            pc <= 0;

        else if (final_pc_write) begin

            if (branch_taken_ex)

                pc <= branch_target_ex;

            else

                pc <= pc + 4;

        end

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

        .write_enable(final_if_id_write),
        .flush(branch_taken_ex),

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

    wire [4:0] if_id_rs1;
    wire [4:0] if_id_rs2;

    assign if_id_rs1 = rs1_id;
    assign if_id_rs2 = rs2_id;

    // =====================================================
    // CONTROL SIGNALS
    // =====================================================

    wire reg_write_id;
    wire mem_read_id;
    wire mem_write_id;
    wire alu_src_id;
    wire mem_to_reg_id;
    wire branch_id;

    wire [2:0] alu_op_id;

    wire reg_write_safe;
    wire mem_read_safe;
    wire mem_write_safe;
    wire alu_src_safe;
    wire mem_to_reg_safe;
    wire branch_safe;

    wire [2:0] alu_op_safe;

    wire pc_write;
    wire if_id_write;
    wire control_mux_sel;

    control_unit control (

        .opcode(opcode_id),

        .reg_write(reg_write_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),

        .alu_src(alu_src_id),

        .mem_to_reg(mem_to_reg_id),

        .branch(branch_id),

        .alu_op(alu_op_id)

    );

    // =====================================================
    // HAZARD DETECTION UNIT
    // =====================================================

    hazard_detection_unit hazard_unit (

        .id_ex_mem_read(id_ex_mem_read),

        .id_ex_rd(id_ex_rd),

        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),

        .pc_write(pc_write),
        .if_id_write(if_id_write),

        .control_mux_sel(control_mux_sel)

    );

    // =====================================================
    // CONTROL BUBBLE INSERTION
    // =====================================================

    assign reg_write_safe =
            (control_mux_sel) ? 1'b0 : reg_write_id;

    assign mem_read_safe =
            (control_mux_sel) ? 1'b0 : mem_read_id;

    assign mem_write_safe =
            (control_mux_sel) ? 1'b0 : mem_write_id;

    assign alu_src_safe =
            (control_mux_sel) ? 1'b0 : alu_src_id;

    assign mem_to_reg_safe =
            (control_mux_sel) ? 1'b0 : mem_to_reg_id;

    assign branch_safe =
            (control_mux_sel) ? 1'b0 : branch_id;

    assign alu_op_safe =
            (control_mux_sel) ? 3'b000 : alu_op_id;

    // =====================================================
    // REGISTER FILE
    // =====================================================

    wire [31:0] read_data1_id;
    wire [31:0] read_data2_id;

    // WB stage signals
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

    // =====================================================
    // IMMEDIATE GENERATOR
    // =====================================================

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
    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;

    wire id_ex_reg_write;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire id_ex_alu_src;
    wire id_ex_mem_to_reg;
    wire id_ex_branch;

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
        .rs1_in(rs1_id),
        .rs2_in(rs2_id),

        .reg_write_in(reg_write_safe),
        .mem_read_in(mem_read_safe),
        .mem_write_in(mem_write_safe),

        .alu_src_in(alu_src_safe),

        .mem_to_reg_in(mem_to_reg_safe),

        .branch_in(branch_safe),

        .alu_op_in(alu_op_safe),

        .pc_out(id_ex_pc),

        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),

        .imm_out(id_ex_imm),

        .rd_out(id_ex_rd),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),

        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),

        .alu_src_out(id_ex_alu_src),

        .mem_to_reg_out(id_ex_mem_to_reg),

        .branch_out(id_ex_branch),

        .alu_op_out(id_ex_alu_op)

    );

    // =====================================================
    // EX STAGE
    // =====================================================

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    wire [31:0] forwarded_a;
    wire [31:0] forwarded_b;

    wire [31:0] alu_input_b_ex;

    wire [31:0] alu_result_ex;

    wire zero_ex;

    wire branch_taken_ex;
    wire [31:0] branch_target_ex;

    assign branch_taken_ex =
            id_ex_branch && zero_ex;

    assign branch_target_ex =
            id_ex_pc + id_ex_imm;

    // =====================================================
    // FORWARDING UNIT
    // =====================================================

    forwarding_unit forwarding (

        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),

        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),

        .forward_a(forward_a),
        .forward_b(forward_b)

    );

    // =====================================================
    // FORWARDING MUXES
    // =====================================================

    assign forwarded_a =

            (forward_a == 2'b10) ? ex_mem_alu_result :

            (forward_a == 2'b01) ? writeback_data :

            id_ex_read_data1;

    assign forwarded_b =

            (forward_b == 2'b10) ? ex_mem_alu_result :

            (forward_b == 2'b01) ? writeback_data :

            id_ex_read_data2;

    // =====================================================
    // ALU INPUT MUX
    // =====================================================

    assign alu_input_b_ex =

            (id_ex_alu_src) ?

            id_ex_imm :

            forwarded_b;

    // =====================================================
    // ALU
    // =====================================================

    alu alu_unit (

        .a(forwarded_a),
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