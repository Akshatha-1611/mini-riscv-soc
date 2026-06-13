// ============================================================
// Register File
// 32 x 32-bit registers, x0 hardwired to 0
// Dual read ports, single write port
// Write on rising edge, read combinationally
// ============================================================
`timescale 1ns/1ps

module register_file (
    input  wire        clk,
    input  wire        rst_n,
    // Read ports
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    // Write port
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        we
);

    reg [31:0] regs [0:31];
    integer i;

    // x0 is always 0; write other regs on rising edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (we && rd_addr != 5'b0)
                regs[rd_addr] <= rd_data;
        end
    end

    // Combinational reads; x0 always reads 0
    assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];

endmodule
