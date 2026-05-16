module ex_mem (

    input clk,
    input rst,

    input write_enable,

    // Datapath signals
    input [31:0] alu_result_in,
    input [31:0] read_data2_in,

    input [4:0] rd_in,

    // Control signals
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input mem_to_reg_in,

    // Outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] read_data2_out,

    output reg [4:0] rd_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out

);

always @(posedge clk or posedge rst) begin

    if (rst) begin

        alu_result_out <= 0;
        read_data2_out <= 0;

        rd_out <= 0;

        reg_write_out <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        mem_to_reg_out <= 0;

    end

    else if (write_enable) begin

        alu_result_out <= alu_result_in;
        read_data2_out <= read_data2_in;

        rd_out <= rd_in;

        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_to_reg_out <= mem_to_reg_in;

    end

end

endmodule