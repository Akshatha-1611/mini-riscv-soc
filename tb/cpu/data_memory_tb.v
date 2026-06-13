// ============================================================
// Data Memory Testbench
// Tests byte/halfword/word stores and loads (signed/unsigned)
// ============================================================
`timescale 1ns/1ps
module data_memory_tb;
    reg        clk, rst_n;
    reg [31:0] addr, write_data;
    reg        mem_read, mem_write;
    reg [2:0]  width;
    wire[31:0] read_data;

    integer pass_count=0, fail_count=0;

    data_memory dut(.clk(clk),.rst_n(rst_n),.addr(addr),.write_data(write_data),
                    .mem_read(mem_read),.mem_write(mem_write),.width(width),.read_data(read_data));

    always #5 clk=~clk;

    task chk32;
        input [31:0] got, exp;
        input [255:0] name;
        begin
            if (got===exp) begin $display("PASS | %0s | 0x%08h",name,got); pass_count++; end
            else begin $display("FAIL | %0s | got=0x%08h exp=0x%08h",name,got,exp); fail_count++; end
        end
    endtask

    initial begin
        $dumpfile("sim/data_memory_tb.vcd"); $dumpvars(0, data_memory_tb);
        clk=0; rst_n=0; mem_read=0; mem_write=0; addr=0; write_data=0; width=0;
        #12; rst_n=1;

        // SW at addr 0
        @(negedge clk); addr=32'd0; write_data=32'hDEADBEEF; width=3'b010; mem_write=1;
        @(posedge clk); #1; mem_write=0;

        // LW
        mem_read=1; addr=32'd0; width=3'b010; #1;
        chk32(read_data, 32'hDEADBEEF, "LW");
        mem_read=0;

        // SB at addr 4
        @(negedge clk); addr=32'd4; write_data=32'hAB; width=3'b000; mem_write=1;
        @(posedge clk); #1; mem_write=0;
        // LB signed (0xAB = -85 signed)
        mem_read=1; addr=32'd4; width=3'b000; #1;
        chk32(read_data, 32'hFFFFFFAB, "LB signed");
        // LBU unsigned
        width=3'b100; #1;
        chk32(read_data, 32'h000000AB, "LBU");
        mem_read=0;

        // SH at addr 8
        @(negedge clk); addr=32'd8; write_data=32'hCAFE; width=3'b001; mem_write=1;
        @(posedge clk); #1; mem_write=0;
        // LH signed
        mem_read=1; addr=32'd8; width=3'b001; #1;
        chk32(read_data, 32'hFFFFCAFE, "LH signed");
        // LHU
        width=3'b101; #1;
        chk32(read_data, 32'h0000CAFE, "LHU");
        mem_read=0;

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #10 $finish;
    end
endmodule
