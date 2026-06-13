// ============================================================
// Register File Testbench
// Tests: write/read, x0 hardwired zero, reset
// Waveform: sim/register_file_tb.vcd
// ============================================================
`timescale 1ns/1ps

module register_file_tb;

    reg        clk, rst_n;
    reg  [4:0] rs1, rs2, rd_addr;
    reg  [31:0] rd_data;
    reg         we;
    wire [31:0] rd1, rd2;

    integer pass_count = 0, fail_count = 0;

    register_file dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .rs1    (rs1),
        .rs2    (rs2),
        .rd1    (rd1),
        .rd2    (rd2),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .we     (we)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/register_file_tb.vcd");
        $dumpvars(0, register_file_tb);
    end

    task check32;
        input [31:0] got, expected;
        input [255:0] name;
        begin
            if (got === expected) begin
                $display("PASS | %0s | got=0x%08h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %0s | got=0x%08h exp=0x%08h", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; we = 0;
        rs1 = 0; rs2 = 0; rd_addr = 0; rd_data = 0;
        #12 rst_n = 1;

        // Write x1 = 0xDEADBEEF
        @(negedge clk);
        rd_addr = 5'd1; rd_data = 32'hDEADBEEF; we = 1;
        @(posedge clk); #1; we = 0;

        // Write x2 = 0xCAFEBABE
        @(negedge clk);
        rd_addr = 5'd2; rd_data = 32'hCAFEBABE; we = 1;
        @(posedge clk); #1; we = 0;

        // Read x1, x2
        rs1 = 5'd1; rs2 = 5'd2; #1;
        check32(rd1, 32'hDEADBEEF, "read x1");
        check32(rd2, 32'hCAFEBABE, "read x2");

        // x0 always reads 0
        @(negedge clk);
        rd_addr = 5'd0; rd_data = 32'hFFFFFFFF; we = 1;
        @(posedge clk); #1; we = 0;
        rs1 = 5'd0; #1;
        check32(rd1, 32'h0, "x0 hardwired 0");

        // Write all 31 registers
        begin: blk
            integer i;
            for (i = 1; i < 32; i = i + 1) begin
                @(negedge clk);
                rd_addr = i; rd_data = i * 32'h11111111; we = 1;
                @(posedge clk); #1; we = 0;
            end
            // Verify
            for (i = 1; i < 32; i = i + 1) begin
                rs1 = i; #1;
                check32(rd1, i * 32'h11111111, "sequential write-read");
            end
        end

        // Reset clears all
        rst_n = 0; #15; rst_n = 1; #5;
        rs1 = 5'd1; rs2 = 5'd31; #1;
        check32(rd1, 32'h0, "x1 cleared after reset");
        check32(rd2, 32'h0, "x31 cleared after reset");

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end

endmodule
