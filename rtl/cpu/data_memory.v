// ============================================================
// Data Memory
// 4KB byte-addressable SRAM
// Supports byte/halfword/word loads (signed & unsigned) and stores
// ============================================================
`timescale 1ns/1ps

module data_memory #(
    parameter MEM_SIZE = 4096 // bytes
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  width,      // funct3: 000=LB,001=LH,010=LW,100=LBU,101=LHU
    output reg  [31:0] read_data
);

    reg [7:0] mem [0:MEM_SIZE-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            mem[i] = 8'b0;
    end

    // Write (byte enables)
    always @(posedge clk) begin
        if (mem_write) begin
            case (width[1:0])
                2'b00: begin // SB
                    mem[addr]     <= write_data[7:0];
                end
                2'b01: begin // SH
                    mem[addr]     <= write_data[7:0];
                    mem[addr+1]   <= write_data[15:8];
                end
                2'b10: begin // SW
                    mem[addr]     <= write_data[7:0];
                    mem[addr+1]   <= write_data[15:8];
                    mem[addr+2]   <= write_data[23:16];
                    mem[addr+3]   <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end

    // Read (combinational for pipeline compatibility)
    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            case (width)
                3'b000: // LB  – signed byte
                    read_data = {{24{mem[addr][7]}}, mem[addr]};
                3'b001: // LH  – signed halfword
                    read_data = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]};
                3'b010: // LW  – word
                    read_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
                3'b100: // LBU – unsigned byte
                    read_data = {24'b0, mem[addr]};
                3'b101: // LHU – unsigned halfword
                    read_data = {16'b0, mem[addr+1], mem[addr]};
                default: read_data = 32'b0;
            endcase
        end
    end

endmodule
