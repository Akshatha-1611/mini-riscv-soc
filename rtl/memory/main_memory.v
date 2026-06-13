// ============================================================
// Main Memory
// Word-addressed, 64KB, with configurable access latency
// Simulates DRAM latency for cache miss behavior
// ============================================================
`timescale 1ns/1ps

module main_memory #(
    parameter MEM_WORDS   = 16384, // 64KB / 4 bytes
    parameter LATENCY     = 4      // Clock cycles to respond
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output reg         ready
);

    reg [31:0] mem [0:MEM_WORDS-1];
    reg [2:0]  lat_cnt;
    reg        pending_read;
    reg [31:0] pend_addr;
    integer i;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'hDEADBEEF;
        lat_cnt      = 3'b0;
        pending_read = 1'b0;
        rdata        = 32'b0;
        ready        = 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready        <= 1'b0;
            pending_read <= 1'b0;
            lat_cnt      <= 3'b0;
        end else begin
            ready <= 1'b0;

            // Immediate write with ready
            if (we) begin
                mem[addr[31:2]] <= wdata;
                ready           <= 1'b1;
            end

            // Latency-modelled read
            if (re && !pending_read) begin
                pending_read <= 1'b1;
                pend_addr    <= addr;
                lat_cnt      <= 3'b0;
            end

            if (pending_read) begin
                if (lat_cnt == LATENCY - 1) begin
                    rdata        <= mem[pend_addr[31:2]];
                    ready        <= 1'b1;
                    pending_read <= 1'b0;
                end else begin
                    lat_cnt <= lat_cnt + 1'b1;
                end
            end
        end
    end

endmodule
