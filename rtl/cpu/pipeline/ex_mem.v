// ============================================================
// EX/MEM Pipeline Register
// Carries ALU result and control signals to Memory stage
// ============================================================
`timescale 1ns/1ps

module ex_mem (
    input  wire        clk,
    input  wire        rst_n,

    // Control inputs
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [2:0]  mem_width_in,

    // Data inputs
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,   // Store data
    input  wire [4:0]  rd_in,
    input  wire [31:0] pc_plus4_in,   // For JAL/JALR return addr

    // Control outputs
    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [2:0]  mem_width_out,

    // Data outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_data_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] pc_plus4_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_width_out  <= 3'b0;
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;
            rd_out         <= 5'b0;
            pc_plus4_out   <= 32'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_width_out  <= mem_width_in;
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            rd_out         <= rd_in;
            pc_plus4_out   <= pc_plus4_in;
        end
    end

endmodule
