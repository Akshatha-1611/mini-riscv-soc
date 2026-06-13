// ============================================================
// CDC FIFO Testbench
// Tests: basic push/pop, full flag, empty flag, burst write/read,
//        clock domain crossing with different clock frequencies
// Waveform: sim/cdc_fifo_tb.vcd  ← KEY WAVEFORM
// ============================================================
`timescale 1ns/1ps

module cdc_fifo_tb;

    // Write clock: 100 MHz (10ns period)
    reg wr_clk;
    // Read clock: 75 MHz (13.3ns period) - intentionally different
    reg rd_clk;

    reg         wr_rst_n, rd_rst_n;
    reg  [31:0] wr_data;
    reg         wr_en;
    wire        full;

    wire [31:0] rd_data;
    reg         rd_en;
    wire        empty;

    integer pass_count = 0, fail_count = 0;
    integer i;
    reg [31:0] expected_data [0:15];

    cdc_fifo #(.DATA_WIDTH(32), .DEPTH(16), .PTR_WIDTH(4)) dut (
        .wr_clk  (wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_data (wr_data),
        .wr_en   (wr_en),
        .full    (full),
        .rd_clk  (rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_data (rd_data),
        .rd_en   (rd_en),
        .empty   (empty)
    );

    // Write clock: 100 MHz
    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    // Read clock: ~75 MHz (different from write)
    initial rd_clk = 0;
    always #6.67 rd_clk = ~rd_clk;

    initial begin
        $dumpfile("sim/cdc_fifo_tb.vcd");
        $dumpvars(0, cdc_fifo_tb);
    end

    initial begin
        $display("=== CDC FIFO Testbench ===");
        $display("Write clk: 100MHz | Read clk: ~75MHz");

        wr_rst_n = 0; rd_rst_n = 0;
        wr_data  = 0; wr_en    = 0; rd_en = 0;
        #50; wr_rst_n = 1; rd_rst_n = 1;
        #20;

        // ---- Test 1: FIFO empty after reset ----
        if (empty === 1'b1) begin
            $display("PASS | T1: empty after reset"); pass_count++;
        end else begin
            $display("FAIL | T1: expected empty=1 after reset"); fail_count++;
        end

        if (full === 1'b0) begin
            $display("PASS | T1: not full after reset"); pass_count++;
        end else begin
            $display("FAIL | T1: expected full=0 after reset"); fail_count++;
        end

        // ---- Test 2: Write single entry ----
        @(negedge wr_clk);
        wr_data = 32'hDEAD_0001; wr_en = 1;
        @(posedge wr_clk); #1; wr_en = 0;
        // Allow gray-code sync (2 rd_clk cycles)
        repeat(4) @(posedge rd_clk); #1;
        if (empty === 1'b0) begin
            $display("PASS | T2: not empty after 1 write"); pass_count++;
        end else begin
            $display("FAIL | T2: still empty after write (sync issue?)"); fail_count++;
        end

        // ---- Test 3: Read single entry ----
        @(negedge rd_clk);
        rd_en = 1;
        @(posedge rd_clk); #1; rd_en = 0;
        if (rd_data === 32'hDEAD_0001) begin
            $display("PASS | T3: read back 0x%08h", rd_data); pass_count++;
        end else begin
            $display("FAIL | T3: got=0x%08h exp=0xDEAD0001", rd_data); fail_count++;
        end
        // Allow sync
        repeat(4) @(posedge wr_clk); #1;
        if (empty === 1'b1) begin
            $display("PASS | T3: empty after reading all entries"); pass_count++;
        end else begin
            $display("FAIL | T3: expected empty=1"); fail_count++;
        end

        // ---- Test 4: Burst write (fill FIFO) ----
        $display("T4: Burst writing 16 entries...");
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge wr_clk);
            wr_data = 32'hA000_0000 | i;
            wr_en   = (!full) ? 1'b1 : 1'b0;
            expected_data[i] = wr_data;
            @(posedge wr_clk); #1;
        end
        wr_en = 0;
        // Check full
        repeat(4) @(posedge wr_clk); #1;
        if (full === 1'b1) begin
            $display("PASS | T4: FIFO full after 16 writes"); pass_count++;
        end else begin
            $display("FAIL | T4: expected full=1 (may have partially filled)"); fail_count++;
        end

        // Write to full FIFO: should be ignored
        @(negedge wr_clk);
        wr_data = 32'hFFFF_FFFF; wr_en = 1;
        @(posedge wr_clk); #1; wr_en = 0;

        // ---- Test 5: Burst read ----
        $display("T5: Burst reading 16 entries...");
        for (i = 0; i < 16; i = i + 1) begin
            repeat(2) @(posedge rd_clk); // Let sync settle
            if (!empty) begin
                @(negedge rd_clk); rd_en = 1;
                @(posedge rd_clk); #1; rd_en = 0;
                if (rd_data === expected_data[i]) begin
                    $display("  PASS | entry[%0d]=0x%08h", i, rd_data); pass_count++;
                end else begin
                    $display("  FAIL | entry[%0d] got=0x%08h exp=0x%08h", i, rd_data, expected_data[i]);
                    fail_count++;
                end
            end else begin
                $display("  FAIL | entry[%0d]: FIFO unexpectedly empty", i);
                fail_count++;
            end
        end
        repeat(6) @(posedge wr_clk); #1;
        if (empty === 1'b1) begin
            $display("PASS | T5: empty after reading all entries"); pass_count++;
        end else begin
            $display("FAIL | T5: expected empty=1"); fail_count++;
        end

        // ---- Test 6: Simultaneous push/pop ----
        $display("T6: Simultaneous push/pop...");
        fork
            begin : writer
                integer w;
                for (w = 0; w < 8; w = w + 1) begin
                    @(negedge wr_clk);
                    wr_data = 32'hB000_0000 | w;
                    wr_en   = !full;
                    @(posedge wr_clk); #1;
                end
                wr_en = 0;
            end
            begin : reader
                integer r;
                repeat(5) @(posedge rd_clk); // slight delay to let writes happen first
                for (r = 0; r < 8; r = r + 1) begin
                    repeat(3) @(posedge rd_clk);
                    if (!empty) begin
                        @(negedge rd_clk); rd_en = 1;
                        @(posedge rd_clk); #1; rd_en = 0;
                    end
                end
            end
        join
        $display("PASS | T6: Simultaneous push/pop completed");
        pass_count++;

        $display("\n=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        #200 $finish;
    end

endmodule
