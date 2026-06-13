// ============================================================
// Pipelined Datapath
// 5-stage RISC-V pipeline: IF → ID → EX → MEM → WB
// Includes: forwarding, hazard detection, branch resolution
// ============================================================
`timescale 1ns/1ps

module pipelined_datapath (
    input  wire        clk,
    input  wire        rst_n,
    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data,
    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re,
    output wire [2:0]  dmem_width,
    input  wire [31:0] dmem_rdata,
    // Debug: expose register file write-back
    output wire [4:0]  wb_rd,
    output wire [31:0] wb_data,
    output wire        wb_we
);

    // =========================================================
    // Stage 1: IF — Instruction Fetch
    // =========================================================
    reg  [31:0] pc;
    wire [31:0] pc_plus4   = pc + 32'd4;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire [31:0] jalr_target;
    wire        branch_taken;
    wire        ex_jump;
    wire        ex_jalr;
    wire        pc_write_en;

    assign imem_addr = pc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'b0;
        else if (pc_write_en) begin
            if      (ex_jump)       pc <= jump_target;
            else if (ex_jalr)       pc <= jalr_target;
            else if (branch_taken)  pc <= branch_target;
            else                    pc <= pc_plus4;
        end
    end

    // =========================================================
    // IF/ID Register
    // =========================================================
    wire        if_id_write_en;
    wire        if_id_flush_sig;
    wire [31:0] id_pc;
    wire [31:0] id_instr;

    if_id u_if_id (
        .clk     (clk),
        .rst_n   (rst_n),
        .flush   (if_id_flush_sig),
        .stall   (!if_id_write_en),
        .if_pc   (pc),
        .if_instr(imem_data),
        .id_pc   (id_pc),
        .id_instr(id_instr)
    );

    // =========================================================
    // Stage 2: ID — Decode
    // =========================================================
    wire [6:0]  id_opcode = id_instr[6:0];
    wire [4:0]  id_rd     = id_instr[11:7];
    wire [2:0]  id_funct3 = id_instr[14:12];
    wire [4:0]  id_rs1    = id_instr[19:15];
    wire [4:0]  id_rs2    = id_instr[24:20];
    wire [6:0]  id_funct7 = id_instr[31:25];

    // Control signals
    wire        id_reg_write, id_mem_to_reg, id_mem_read, id_mem_write;
    wire        id_alu_src, id_branch, id_jump, id_jalr;
    wire [3:0]  id_alu_ctrl;
    wire [2:0]  id_mem_width;

    control_unit u_ctrl (
        .opcode    (id_opcode),
        .funct3    (id_funct3),
        .funct7    (id_funct7),
        .reg_write (id_reg_write),
        .mem_read  (id_mem_read),
        .mem_write (id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src   (id_alu_src),
        .branch    (id_branch),
        .jump      (id_jump),
        .jalr      (id_jalr),
        .alu_ctrl  (id_alu_ctrl),
        .mem_width (id_mem_width)
    );

    // Register file reads
    wire [31:0] id_rs1_data, id_rs2_data;

    register_file u_regfile (
        .clk     (clk),
        .rst_n   (rst_n),
        .rs1     (id_rs1),
        .rs2     (id_rs2),
        .rd1     (id_rs1_data),
        .rd2     (id_rs2_data),
        .rd_addr (wb_rd),
        .rd_data (wb_data),
        .we      (wb_we)
    );

    // Immediate generation
    wire [31:0] id_imm;

    immediate_generator u_immgen (
        .instruction(id_instr),
        .imm_out    (id_imm)
    );

    // =========================================================
    // Hazard Detection
    // =========================================================
    wire        id_ex_flush_sig;
    wire [4:0]  ex_rd_wire;
    wire        ex_mem_read_wire;

    hazard_detection_unit u_hazard (
        .id_ex_mem_read (ex_mem_read_wire),
        .id_ex_rd       (ex_rd_wire),
        .if_id_rs1      (id_rs1),
        .if_id_rs2      (id_rs2),
        .branch_taken   (branch_taken),
        .jump           (ex_jump),
        .jalr           (ex_jalr),
        .pc_write       (pc_write_en),
        .if_id_write    (if_id_write_en),
        .id_ex_flush    (id_ex_flush_sig),
        .if_id_flush    (if_id_flush_sig)
    );

    // =========================================================
    // ID/EX Register
    // =========================================================
    wire        ex_reg_write, ex_mem_to_reg, ex_mem_write;
    wire        ex_alu_src, ex_branch, ex_jump_wire, ex_jalr_wire;
    wire [3:0]  ex_alu_ctrl;
    wire [2:0]  ex_mem_width;
    wire [31:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2;

    assign ex_jump     = ex_jump_wire;
    assign ex_jalr     = ex_jalr_wire;
    assign ex_rd_wire  = ex_rd_w;
    wire [4:0] ex_rd_w;

    id_ex u_id_ex (
        .clk           (clk),
        .rst_n         (rst_n),
        .flush         (id_ex_flush_sig),
        .reg_write_in  (id_reg_write),
        .mem_to_reg_in (id_mem_to_reg),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .alu_src_in    (id_alu_src),
        .branch_in     (id_branch),
        .jump_in       (id_jump),
        .jalr_in       (id_jalr),
        .alu_ctrl_in   (id_alu_ctrl),
        .mem_width_in  (id_mem_width),
        .pc_in         (id_pc),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .imm_in        (id_imm),
        .rs1_in        (id_rs1),
        .rs2_in        (id_rs2),
        .rd_in         (id_rd),
        .reg_write_out (ex_reg_write),
        .mem_to_reg_out(ex_mem_to_reg),
        .mem_read_out  (ex_mem_read_wire),
        .mem_write_out (ex_mem_write),
        .alu_src_out   (ex_alu_src),
        .branch_out    (ex_branch),
        .jump_out      (ex_jump_wire),
        .jalr_out      (ex_jalr_wire),
        .alu_ctrl_out  (ex_alu_ctrl),
        .mem_width_out (ex_mem_width),
        .pc_out        (ex_pc),
        .rs1_data_out  (ex_rs1_data),
        .rs2_data_out  (ex_rs2_data),
        .imm_out       (ex_imm),
        .rs1_out       (ex_rs1),
        .rs2_out       (ex_rs2),
        .rd_out        (ex_rd_w)
    );

    assign ex_rd_wire = ex_rd_w;

    // =========================================================
    // Stage 3: EX — Execute
    // =========================================================
    // Forwarding
    wire [1:0]  fwd_a, fwd_b;
    wire        mem_wb_reg_write;
    wire [4:0]  mem_mem_rd, wb_rd_wire;
    wire [31:0] ex_mem_alu_result; // forwarded from EX/MEM
    wire [31:0] mem_wb_writeback;  // forwarded from MEM/WB

    forwarding_unit u_fwd (
        .ex_rs1          (ex_rs1),
        .ex_rs2          (ex_rs2),
        .ex_mem_reg_write(ex_mem_reg_write_wire),
        .ex_mem_rd       (ex_mem_rd_wire),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd       (wb_rd),
        .forward_a       (fwd_a),
        .forward_b       (fwd_b)
    );

    wire        ex_mem_reg_write_wire;
    wire [4:0]  ex_mem_rd_wire;
    wire [31:0] ex_mem_alu_res_wire;

    // Operand A mux
    wire [31:0] alu_op_a = (fwd_a == 2'b10) ? ex_mem_alu_res_wire :
                           (fwd_a == 2'b01) ? mem_wb_writeback    :
                                              ex_rs1_data;

    // Operand B before ALU-src mux
    wire [31:0] fwd_b_data = (fwd_b == 2'b10) ? ex_mem_alu_res_wire :
                             (fwd_b == 2'b01) ? mem_wb_writeback    :
                                               ex_rs2_data;

    wire [31:0] alu_op_b = ex_alu_src ? ex_imm : fwd_b_data;

    // ALU
    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .a       (alu_op_a),
        .b       (alu_op_b),
        .alu_ctrl(ex_alu_ctrl),
        .result  (alu_result),
        .zero    (alu_zero)
    );

    // Branch target address
    assign branch_target = ex_pc + ex_imm;
    assign jump_target   = ex_pc + ex_imm;
    assign jalr_target   = (alu_op_a + ex_imm) & ~32'b1;

    // Branch resolution
    wire [2:0] ex_funct3 = ex_mem_width; // funct3 stored in mem_width for branches
    reg branch_taken_r;
    always @(*) begin
        branch_taken_r = 1'b0;
        if (ex_branch) begin
            case (ex_mem_width)
                3'b000: branch_taken_r = alu_zero;           // BEQ
                3'b001: branch_taken_r = !alu_zero;          // BNE
                3'b100: branch_taken_r = alu_result[0];      // BLT
                3'b101: branch_taken_r = !alu_result[0];     // BGE
                3'b110: branch_taken_r = alu_result[0];      // BLTU
                3'b111: branch_taken_r = !alu_result[0];     // BGEU
                default: branch_taken_r = 1'b0;
            endcase
        end
    end
    assign branch_taken = branch_taken_r;

    wire [31:0] ex_pc_plus4 = ex_pc + 32'd4;

    // =========================================================
    // EX/MEM Register
    // =========================================================
    wire        mem_mem_to_reg, mem_mem_read, mem_mem_write;
    wire [2:0]  mem_mem_width;
    wire [31:0] mem_alu_result, mem_rs2_data, mem_pc_plus4;

    ex_mem u_ex_mem (
        .clk           (clk),
        .rst_n         (rst_n),
        .reg_write_in  (ex_reg_write),
        .mem_to_reg_in (ex_mem_to_reg),
        .mem_read_in   (ex_mem_read_wire),
        .mem_write_in  (ex_mem_write),
        .mem_width_in  (ex_mem_width),
        .alu_result_in (alu_result),
        .rs2_data_in   (fwd_b_data),
        .rd_in         (ex_rd_w),
        .pc_plus4_in   (ex_pc_plus4),
        .reg_write_out (ex_mem_reg_write_wire),
        .mem_to_reg_out(mem_mem_to_reg),
        .mem_read_out  (mem_mem_read),
        .mem_write_out (mem_mem_write),
        .mem_width_out (mem_mem_width),
        .alu_result_out(ex_mem_alu_res_wire),
        .rs2_data_out  (mem_rs2_data),
        .rd_out        (ex_mem_rd_wire),
        .pc_plus4_out  (mem_pc_plus4)
    );

    assign ex_mem_alu_result = ex_mem_alu_res_wire;

    // =========================================================
    // Stage 4: MEM — Memory Access
    // =========================================================
    assign dmem_addr  = ex_mem_alu_res_wire;
    assign dmem_wdata = mem_rs2_data;
    assign dmem_we    = mem_mem_write;
    assign dmem_re    = mem_mem_read;
    assign dmem_width = mem_mem_width;

    // =========================================================
    // MEM/WB Register
    // =========================================================
    wire        wb_mem_to_reg;
    wire [31:0] wb_mem_data, wb_alu_result, wb_pc_plus4;

    mem_wb u_mem_wb (
        .clk           (clk),
        .rst_n         (rst_n),
        .reg_write_in  (ex_mem_reg_write_wire),
        .mem_to_reg_in (mem_mem_to_reg),
        .mem_data_in   (dmem_rdata),
        .alu_result_in (ex_mem_alu_res_wire),
        .rd_in         (ex_mem_rd_wire),
        .pc_plus4_in   (mem_pc_plus4),
        .reg_write_out (mem_wb_reg_write),
        .mem_to_reg_out(wb_mem_to_reg),
        .mem_data_out  (wb_mem_data),
        .alu_result_out(wb_alu_result),
        .rd_out        (wb_rd),
        .pc_plus4_out  (wb_pc_plus4)
    );

    // =========================================================
    // Stage 5: WB — Writeback
    // =========================================================
    assign wb_we   = mem_wb_reg_write;
    assign wb_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

    // MEM/WB forward value for forwarding unit
    assign mem_wb_writeback = wb_data;

endmodule
