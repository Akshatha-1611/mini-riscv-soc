module id_ex (

    input clk,
    input rst,

    input write_enable,

    // Datapath signals
    input [31:0] pc_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] imm_in,

    input [4:0] rd_in,

    // Control signals
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input alu_src_in,
    input mem_to_reg_in,

    input [2:0] alu_op_in,

    // Outputs
    output reg [31:0] pc_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_out,

    output reg [4:0] rd_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg alu_src_out,
    output reg mem_to_reg_out,

    output reg [2:0] alu_op_out

);

always @(posedge clk or posedge rst) begin

    if (rst) begin

        pc_out <= 0;
        read_data1_out <= 0;
        read_data2_out <= 0;
        imm_out <= 0;

        rd_out <= 0;

        reg_write_out <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        alu_src_out <= 0;
        mem_to_reg_out <= 0;

        alu_op_out <= 0;

    end

    else if (write_enable) begin

        pc_out <= pc_in;

        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;

        imm_out <= imm_in;

        rd_out <= rd_in;

        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        alu_src_out <= alu_src_in;
        mem_to_reg_out <= mem_to_reg_in;

        alu_op_out <= alu_op_in;

    end

end

endmodule