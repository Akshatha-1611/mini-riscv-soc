module register_file (

    input clk,
    input rst,

    // Read ports
    input  [4:0] rs1,
    input  [4:0] rs2,

    // Write port
    input  [4:0] rd,
    input  [31:0] write_data,
    input  reg_write,

    // Read data outputs
    output [31:0] read_data1,
    output [31:0] read_data2

);

    // 32 registers, each 32-bit
    reg [31:0] registers [31:0];

    integer i;

    // Reset + Write Logic
    always @(posedge clk or posedge rst) begin

        if (rst) begin

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;

        end

        else begin

            // x0 must always remain 0
            if (reg_write && (rd != 5'b00000))
                registers[rd] <= write_data;

        end

    end

    // Combinational Read
    assign read_data1 = (rs1 == 5'b00000) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b00000) ? 32'b0 : registers[rs2];

endmodule