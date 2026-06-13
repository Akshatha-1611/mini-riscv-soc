// ============================================================
// Pipelined CPU Integration Testbench
// Tests: R-type, I-type, Load/Store, Branch, Forwarding, Hazards
// This is the PRIMARY waveform capture test.
// Waveform: sim/pipelined_cpu_tb.vcd
// ============================================================
`timescale 1ns/1ps

module pipelined_cpu_tb;

    reg  clk, rst_n;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;
    wire        wb_we;

    integer cycle_count = 0;

    cpu_top #(.MEM_FILE("")) u_cpu (
        .clk    (clk),
        .rst_n  (rst_n),
        .wb_rd  (wb_rd),
        .wb_data(wb_data),
        .wb_we  (wb_we)
    );

    always #5 clk = ~clk;
    always @(posedge clk) cycle_count <= cycle_count + 1;

    // Monitor writeback
    always @(posedge clk) begin
        if (wb_we && wb_rd != 0)
            $display("[Cycle %3d] WB: x%0d <= 0x%08h (%0d)", cycle_count, wb_rd, wb_data, wb_data);
    end

    // ---- Program: hand-assembled RV32I ----
    // Tests forwarding, load-use stall, branch
    // ADDI x1,x0,5         x1=5
    // ADDI x2,x0,10        x2=10
    // ADD  x3,x1,x2        x3=15  (EX→EX forward)
    // SUB  x4,x3,x1        x4=10  (EX→EX forward)
    // ADDI x5,x0,20        x5=20
    // SW   x5,0(x0)        mem[0]=20
    // LW   x6,0(x0)        x6=20  (load)
    // ADD  x7,x6,x1        x7=25  (load-use: 1 stall)
    // SLTI x8,x7,30        x8=1   (25<30)
    // BEQ  x8,x1,+8        not taken (x8=1,x1=5)
    // ADDI x9,x0,99        x9=99
    // XOR  x10,x1,x2       x10=15
    // SLL  x11,x1,x2       ... (shift by 10 = overflows, but tests path)
    // SRAI x12,x10,1       x12=7
    // AUIPC x13,0          x13=PC
    // JALR x14,x1,4        jump to x1+4 (may leave pipeline)
    // NOP (x15 etc.)

    initial begin
        $dumpfile("sim/pipelined_cpu_tb.vcd");
        $dumpvars(0, pipelined_cpu_tb);

        // Manually load program into instruction memory
        // (cpu_top instantiates instruction_memory internally)
        u_cpu.u_imem.mem[0]  = 32'h00500093; // ADDI x1,x0,5
        u_cpu.u_imem.mem[1]  = 32'h00A00113; // ADDI x2,x0,10
        u_cpu.u_imem.mem[2]  = 32'h002081B3; // ADD  x3,x1,x2
        u_cpu.u_imem.mem[3]  = 32'h40118233; // SUB  x4,x3,x1
        u_cpu.u_imem.mem[4]  = 32'h01400293; // ADDI x5,x0,20
        u_cpu.u_imem.mem[5]  = 32'h00502023; // SW   x5,0(x0)
        u_cpu.u_imem.mem[6]  = 32'h00002303; // LW   x6,0(x0)
        u_cpu.u_imem.mem[7]  = 32'h001303B3; // ADD  x7,x6,x1  (load-use stall)
        u_cpu.u_imem.mem[8]  = 32'h01E3A413; // SLTI x8,x7,30
        u_cpu.u_imem.mem[9]  = 32'h00108463; // BEQ  x1,x1,+8 (taken: skip next)
        u_cpu.u_imem.mem[10] = 32'h00000013; // NOP (skipped)
        u_cpu.u_imem.mem[11] = 32'h06300493; // ADDI x9,x0,99
        u_cpu.u_imem.mem[12] = 32'h00214533; // XOR  x10,x2,x2
        u_cpu.u_imem.mem[13] = 32'h00209593; // SLLI x11,x1,2
        u_cpu.u_imem.mem[14] = 32'h40155613; // SRAI x12,x10,1
        u_cpu.u_imem.mem[15] = 32'h00000097; // AUIPC x1,0
        u_cpu.u_imem.mem[16] = 32'h00000013; // NOP
        u_cpu.u_imem.mem[17] = 32'h00000013; // NOP
        u_cpu.u_imem.mem[18] = 32'h00000013; // NOP
        u_cpu.u_imem.mem[19] = 32'h00000013; // NOP
        u_cpu.u_imem.mem[20] = 32'h00000013; // NOP

        // Reset
        clk = 0; rst_n = 0;
        #22; rst_n = 1;

        // Run for enough cycles
        #500;

        // Check expected register values after ~50 cycles
        $display("\n=== Final Register State ===");
        $display("x1  = %0d (expect 5)",  u_cpu.u_datapath.u_regfile.regs[1]);
        $display("x2  = %0d (expect 10)", u_cpu.u_datapath.u_regfile.regs[2]);
        $display("x3  = %0d (expect 15)", u_cpu.u_datapath.u_regfile.regs[3]);
        $display("x4  = %0d (expect 10)", u_cpu.u_datapath.u_regfile.regs[4]);
        $display("x5  = %0d (expect 20)", u_cpu.u_datapath.u_regfile.regs[5]);
        $display("x6  = %0d (expect 20)", u_cpu.u_datapath.u_regfile.regs[6]);
        $display("x7  = %0d (expect 25)", u_cpu.u_datapath.u_regfile.regs[7]);
        $display("x8  = %0d (expect 1)",  u_cpu.u_datapath.u_regfile.regs[8]);
        $display("x9  = %0d (expect 99)", u_cpu.u_datapath.u_regfile.regs[9]);
        $display("x11 = %0d (expect 20)", u_cpu.u_datapath.u_regfile.regs[11]);

        $display("\nTotal cycles: %0d", cycle_count);
        #50 $finish;
    end

endmodule
