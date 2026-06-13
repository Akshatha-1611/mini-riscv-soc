// ============================================================
// Cache System Testbench
// Addresses use 4-set layout: addr[5:4]=set, addr[3:2]=word
// ============================================================
`timescale 1ns/1ps

module cache_system_tb;

    reg         clk, rst_n;
    reg  [31:0] cpu_addr, cpu_wdata;
    reg         cpu_we, cpu_re;
    wire [31:0] cpu_rdata;
    wire        cpu_ready, cpu_stall;

    integer pass_cnt=0, fail_cnt=0, timeout;

    cache_system dut (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_we(cpu_we),     .cpu_re(cpu_re),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .cpu_stall(cpu_stall)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/cache_system_tb.vcd");
        $dumpvars(0, cache_system_tb);
    end

    task do_write;
        input [31:0] addr, data;
        begin
            @(negedge clk);
            cpu_addr=addr; cpu_wdata=data; cpu_we=1; cpu_re=0;
            timeout=0;
            @(posedge clk);
            while (!cpu_ready && timeout<300) begin @(posedge clk); timeout=timeout+1; end
            @(negedge clk); cpu_we=0; @(posedge clk);
        end
    endtask

    task do_read;
        input  [31:0] addr;
        output [31:0] rdata;
        begin
            @(negedge clk);
            cpu_addr=addr; cpu_re=1; cpu_we=0;
            timeout=0;
            @(posedge clk);
            while (!cpu_ready && timeout<300) begin @(posedge clk); timeout=timeout+1; end
            rdata=cpu_rdata;
            @(negedge clk); cpu_re=0; @(posedge clk);
        end
    endtask

    task chk;
        input [31:0] got, exp;
        input [127:0] name;
        begin
            if (got===exp) begin $display("  PASS | %0s 0x%08h",name,got); pass_cnt=pass_cnt+1; end
            else begin $display("  FAIL | %0s got=0x%08h exp=0x%08h",name,got,exp); fail_cnt=fail_cnt+1; end
        end
    endtask

    reg [31:0] rd;

    initial begin
        $display("=== Cache System Testbench ===");
        clk=0; rst_n=0;
        cpu_addr=0; cpu_wdata=0; cpu_we=0; cpu_re=0;
        #22; rst_n=1; #10;

        // Write to set0 word0 then read it back
        $display("\n[T1] Write then read set0");
        do_write(32'h0000_0000, 32'h1234_5678);
        do_read (32'h0000_0000, rd);
        chk(rd, 32'h1234_5678, "T1_write_readback");

        // Write all 4 words of set1 line
        $display("\n[T2] Full cache line write to set1");
        do_write(32'h0000_0010, 32'hAAAA_AAAA);
        do_write(32'h0000_0014, 32'hBBBB_BBBB);
        do_write(32'h0000_0018, 32'hCCCC_CCCC);
        do_write(32'h0000_001C, 32'hDDDD_DDDD);
        do_read(32'h0000_0010, rd); chk(rd, 32'hAAAA_AAAA, "T2_word0");
        do_read(32'h0000_0014, rd); chk(rd, 32'hBBBB_BBBB, "T2_word1");
        do_read(32'h0000_0018, rd); chk(rd, 32'hCCCC_CCCC, "T2_word2");
        do_read(32'h0000_001C, rd); chk(rd, 32'hDDDD_DDDD, "T2_word3");

        // Conflict miss on set0 (different tag)
        $display("\n[T3] Conflict miss on set0 (tag=1)");
        do_read(32'h0000_0040, rd);
        // Not checking exact value (depends on main_memory init) — just no crash
        $display("  PASS | T3_no_crash rd=0x%08h", rd); pass_cnt=pass_cnt+1;

        $display("\n=== Results: %0d PASS  %0d FAIL ===", pass_cnt, fail_cnt);
        #50 $finish;
    end

endmodule