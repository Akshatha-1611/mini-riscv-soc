// ============================================================
// Hazard Detection Unit
// Detects load-use hazards (1-cycle stall) and flushes on branch/jump
// ============================================================
`timescale 1ns/1ps

module hazard_detection_unit (
    // ID/EX pipeline register signals
    input  wire        id_ex_mem_read,  // Load instruction in EX
    input  wire [4:0]  id_ex_rd,        // Destination of EX-stage load

    // IF/ID signals (current decode)
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,

    // Branch/jump resolved (from EX stage)
    input  wire        branch_taken,
    input  wire        jump,
    input  wire        jalr,

    // Outputs
    output reg         pc_write,       // 0 = stall PC
    output reg         if_id_write,    // 0 = stall IF/ID
    output reg         id_ex_flush,    // 1 = insert bubble into EX
    output reg         if_id_flush     // 1 = flush for branch/jump
);

    wire load_use_hazard;

    assign load_use_hazard = id_ex_mem_read &&
                             ((id_ex_rd == if_id_rs1) ||
                              (id_ex_rd == if_id_rs2)) &&
                             (id_ex_rd != 5'b0);

    always @(*) begin
        // Defaults: no stall
        pc_write    = 1'b1;
        if_id_write = 1'b1;
        id_ex_flush = 1'b0;
        if_id_flush = 1'b0;

        if (load_use_hazard) begin
            // Stall: freeze PC and IF/ID, bubble into ID/EX
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            id_ex_flush = 1'b1;
        end

        if (branch_taken || jump || jalr) begin
            // Flush the incorrectly fetched instructions
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end
    end

endmodule
