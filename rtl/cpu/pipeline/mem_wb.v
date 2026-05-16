module mem_wb (

    input clk,
    input rst,

    input write_enable,

    // Datapath signals
    input [31:0] mem_data_in,
    input [31:0] alu_result_in,

    input [4:0] rd_in,

    // Control signals
    input reg_write_in,
    input mem_to_reg_in,

    // Outputs
    output reg [31:0] mem_data_out,
    output reg [31:0] alu_result_out,

    output reg [4:0] rd_out,

    output reg reg_write_out,
    output reg mem_to_reg_out

);

always @(posedge clk or posedge rst) begin

    if (rst) begin

        mem_data_out <= 0;
        alu_result_out <= 0;

        rd_out <= 0;

        reg_write_out <= 0;
        mem_to_reg_out <= 0;

    end

    else if (write_enable) begin

        mem_data_out <= mem_data_in;
        alu_result_out <= alu_result_in;

        rd_out <= rd_in;

        reg_write_out <= reg_write_in;
        mem_to_reg_out <= mem_to_reg_in;

    end

end

endmodule