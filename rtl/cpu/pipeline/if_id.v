module if_id (

    input clk,
    input rst,

    input write_enable,
    input flush,

    input [31:0] pc_in,
    input [31:0] instruction_in,

    output reg [31:0] pc_out,
    output reg [31:0] instruction_out

);

always @(posedge clk or posedge rst) begin

    if (rst) begin

        pc_out <= 32'b0;
        instruction_out <= 32'b0;

    end

    else begin

        if (flush) begin

            pc_out <= 0;
            instruction_out <= 0;

        end

        else if (write_enable) begin

            pc_out <= pc_in;
            instruction_out <= instruction_in;

        end

    end

end

endmodule
