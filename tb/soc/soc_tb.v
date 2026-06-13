// ============================================================
// SoC Top-Level Integration Testbench
// Tests the full CPU → Cache → CDC FIFO → Memory chain
// Waveform: sim/soc_tb.vcd
// ============================================================
`timescale 1ns/1ps

module soc_tb;

    reg cpu_clk, mem_clk, rst_n;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;
    wire        wb_we;

    integer cycle_count = 0;

    // CPU clock: 100 MHz
    initial cpu_clk = 0;
    always #5 cpu_clk = ~cpu_clk;

    // Memory clock: 66 MHz (different domain)
    initial mem_clk = 0;
    always #7.5 mem_clk = ~mem_clk;

    always @(posedge cpu_clk) cycle_count <= cycle_count + 1;

    mini_riscv_soc #(.MEM_FILE("")) u_soc (
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst_n  (rst_n),
        .wb_rd  (wb_rd),
        .wb_data(wb_data),
        .wb_we  (wb_we)
    );

    always @(posedge cpu_clk) begin
        if (wb_we && wb_rd != 0)
            $display("[CPU Cycle %3d] WB: x%0d <= 0x%08h", cycle_count, wb_rd, wb_data);
    end

    initial begin
        $dumpfile("sim/soc_tb.vcd");
        $dumpvars(0, soc_tb);

        rst_n = 0;
        #50; rst_n = 1;

        // Let SoC run
        #2000;

        $display("\n[SoC TB] Simulation complete after %0d CPU cycles", cycle_count);
        $finish;
    end

endmodule
