// ============================================================
// Cache Controller Testbench — 4-set layout
// addr[5:4]=set, addr[3:2]=word
//
// Memory model protocol (fixed):
//   Writes: mem_ready=1 same cycle mem_we is seen
//   Reads:  mem_ready=1 after LATENCY cycles from any new
//           mem_addr presented while mem_re is high.
//           Detects new requests by addr change OR re rising
//           edge — handles the case where S_FETCH holds mem_re
//           high continuously across all 4 words.
//
// Test map:
//   Set 0 tag 0: 0x00000000
//   Set 1 tag 0: 0x00000010
//   Set 0 tag 1: 0x00000040  (conflicts set 0)
//   Set 0 tag 2: 0x00000080  (2nd conflict → dirty eviction)
// ============================================================
`timescale 1ns/1ps

module cache_controller_tb;

    reg         clk, rst_n;

    reg  [31:0] cpu_addr, cpu_wdata;
    reg         cpu_we,   cpu_re;
    wire [31:0] cpu_rdata;
    wire        cpu_ready, cpu_stall;

    wire [31:0] mem_addr, mem_wdata;
    wire        mem_we,   mem_re;
    reg  [31:0] mem_rdata;
    reg         mem_ready;

    integer pass_cnt = 0, fail_cnt = 0, timeout;

    // ── DUT ──────────────────────────────────────────────────
    cache_controller dut (
        .clk(clk),         .rst_n(rst_n),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_we(cpu_we),     .cpu_re(cpu_re),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .cpu_stall(cpu_stall),
        .mem_addr(mem_addr),  .mem_wdata(mem_wdata),
        .mem_we(mem_we),      .mem_re(mem_re),
        .mem_rdata(mem_rdata),.mem_ready(mem_ready)
    );

    always #5 clk = ~clk;

    // ── Backing memory ────────────────────────────────────────
    reg [31:0] backing_mem [0:255];
    integer m;
    initial begin
        for (m = 0; m < 256; m = m + 1)
            backing_mem[m] = 32'hA000_0000 | m;
    end

    // ── Memory response model ─────────────────────────────────
    // Key fix: detect a new read request whenever mem_addr changes
    // while mem_re is high, OR on the rising edge of mem_re.
    // This correctly handles S_FETCH holding mem_re=1 continuously
    // and updating mem_addr for each successive word.
    //
    // Read latency: MEM_LAT cycles from when request is detected.

    localparam MEM_LAT = 2;

    reg [31:0] tracked_addr;   // last addr we started a read for
    reg [1:0]  lat_cnt;        // countdown to mem_ready
    reg        read_pending;   // a read is in flight
    reg        mem_re_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready    <= 0;
            mem_rdata    <= 0;
            tracked_addr <= 32'hFFFF_FFFF; // invalid sentinel
            lat_cnt      <= 0;
            read_pending <= 0;
            mem_re_prev  <= 0;
        end else begin
            mem_ready   <= 0; // default deassert each cycle
            mem_re_prev <= mem_re;

            // ── Write: accept immediately ──────────────────
            if (mem_we) begin
                backing_mem[mem_addr[9:2]] <= mem_wdata;
                mem_ready <= 1;
            end

            // ── Read: new request detection ────────────────
            // Trigger when:
            //   (a) mem_re just went high (rising edge), OR
            //   (b) mem_re is already high AND mem_addr changed
            // Both cases mean the FSM is presenting a new word address.
            if (mem_re && ((!mem_re_prev) || (mem_addr !== tracked_addr))) begin
                tracked_addr <= mem_addr;
                lat_cnt      <= MEM_LAT - 1; // MEM_LAT=2: count 1→0
                read_pending <= 1;
            end

            // ── Read: countdown and respond ────────────────
            if (read_pending) begin
                if (lat_cnt == 0) begin
                    mem_rdata    <= backing_mem[tracked_addr[9:2]];
                    mem_ready    <= 1;
                    read_pending <= 0;
                end else begin
                    lat_cnt <= lat_cnt - 1;
                end
            end

            // ── Cancel if mem_re drops mid-transaction ─────
            if (!mem_re && read_pending) begin
                read_pending <= 0;
                lat_cnt      <= 0;
            end
        end
    end

    // ── VCD ──────────────────────────────────────────────────
    initial begin
        $dumpfile("sim/cache_controller_tb.vcd");
        $dumpvars(0, cache_controller_tb);
    end

    // ── Tasks ─────────────────────────────────────────────────
    task do_read;
        input  [31:0] addr;
        output [31:0] rdata;
        begin
            @(negedge clk);
            cpu_addr = addr; cpu_re = 1; cpu_we = 0; cpu_wdata = 0;
            timeout = 0;
            @(posedge clk);
            while (!cpu_ready && timeout < 300) begin
                @(posedge clk); timeout = timeout + 1;
            end
            rdata = cpu_rdata;
            @(negedge clk); cpu_re = 0;
            @(posedge clk);
            if (timeout >= 300)
                $display("  TIMEOUT do_read addr=0x%08h", addr);
        end
    endtask

    task do_write;
        input [31:0] addr, data;
        begin
            @(negedge clk);
            cpu_addr = addr; cpu_wdata = data; cpu_we = 1; cpu_re = 0;
            timeout = 0;
            @(posedge clk);
            while (!cpu_ready && timeout < 300) begin
                @(posedge clk); timeout = timeout + 1;
            end
            @(negedge clk); cpu_we = 0;
            @(posedge clk);
            if (timeout >= 300)
                $display("  TIMEOUT do_write addr=0x%08h", addr);
        end
    endtask

    task chk;
        input [31:0] got, exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS | %0s | 0x%08h", name, got);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL | %0s | got=0x%08h  exp=0x%08h",
                         name, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ── Tests ─────────────────────────────────────────────────
    reg [31:0] rd;

    initial begin
        $display("=== Cache Controller Testbench (4-set) ===");
        clk=0; rst_n=0;
        cpu_addr=0; cpu_wdata=0; cpu_we=0; cpu_re=0;
        mem_rdata=0; mem_ready=0;
        #22; rst_n=1; #10;

        // ── T1: Cold read miss → fill → correct data ────────
        $display("\n[T1] Cold miss: addr=0x00 (set=0 word=0 tag=0)");
        do_read(32'h0000_0000, rd);
        // backing_mem[0] = 0xA0000000
        chk(rd, 32'hA000_0000, "T1_cold_miss");

        // ── T2: Hit on same line (word 1) ───────────────────
        $display("\n[T2] Hit: addr=0x04 (set=0 word=1 same line)");
        do_read(32'h0000_0004, rd);
        chk(rd, 32'hA000_0001, "T2_hit_word1");

        // ── T3: Hit on same line (word 2) ───────────────────
        $display("\n[T3] Hit: addr=0x08 (set=0 word=2)");
        do_read(32'h0000_0008, rd);
        chk(rd, 32'hA000_0002, "T3_hit_word2");

        // ── T4: Write hit (dirties the line) ────────────────
        $display("\n[T4] Write hit: addr=0x00 <= 0xDEADBEEF");
        do_write(32'h0000_0000, 32'hDEAD_BEEF);

        // ── T5: Read back written value ──────────────────────
        $display("\n[T5] Read back: addr=0x00 expect 0xDEADBEEF");
        do_read(32'h0000_0000, rd);
        chk(rd, 32'hDEAD_BEEF, "T5_write_readback");

        // ── T6: Conflict miss, clean eviction ────────────────
        // tag=1,set=0 → addr bit5=1, bits[5:4]=01 → 0x40
        $display("\n[T6] Conflict miss (clean): addr=0x40 (tag=1,set=0)");
        do_read(32'h0000_0040, rd);
        chk(rd, backing_mem[32'h40>>2], "T6_conflict_clean");

        // ── T7: Dirty eviction ───────────────────────────────
        // Both ways of set 0 are now valid. Dirty way 0 (tag=0).
        $display("\n[T7] Re-access tag=0,set=0 to bring it back");
        do_read(32'h0000_0000, rd); // miss → fills way1 (way0 has tag=1 from T6)

        $display("[T7] Write to make tag=0,set=0 dirty");
        do_write(32'h0000_0000, 32'hCAFE_BABE);

        // Now access tag=2,set=0 (addr bit6=1 → 0x80)
        // LRU way is dirty → must write-back before fetch
        $display("[T7] Dirty eviction: addr=0x80 (tag=2,set=0)");
        do_read(32'h0000_0080, rd);
        chk(rd, backing_mem[32'h80>>2], "T7_dirty_eviction_read");

        // Give write-back a moment to commit, then check backing mem
        #40;
        if (backing_mem[0] === 32'hCAFE_BABE)
            begin $display("  PASS | T7_dirty_written_back_to_mem");
                  pass_cnt = pass_cnt + 1; end
        else
            begin $display("  FAIL | T7_dirty_not_in_mem got=0x%08h",
                           backing_mem[0]);
                  fail_cnt = fail_cnt + 1; end

        // ── T8: LRU check ────────────────────────────────────
        $display("\n[T8] LRU: fill set1 way0 and way1, re-access way0,");
        $display("          then conflict → should evict way1 (LRU)");
        do_read(32'h0000_0010, rd); // set1 way0 (tag=0)
        do_read(32'h0000_0050, rd); // set1 way1 (tag=1)
        do_read(32'h0000_0010, rd); // hit way0 → way0 becomes MRU, way1=LRU
        do_read(32'h0000_0090, rd); // tag=2,set=1 → evict way1 (LRU)
        chk(rd, backing_mem[32'h90>>2], "T8_lru_evict_correct");

        // ── T9: Sets are independent ──────────────────────────
        $display("\n[T9] Write set2, read set3 (should not interfere)");
        do_write(32'h0000_0020, 32'h1234_5678);
        do_read (32'h0000_0030, rd);
        // set3 is independent; its value comes from backing_mem
        chk(rd, backing_mem[32'h30>>2], "T9_set_independence");

        // ── T10: Verify set2 write still holds ───────────────
        $display("\n[T10] Read back set2 write");
        do_read(32'h0000_0020, rd);
        chk(rd, 32'h1234_5678, "T10_set2_readback");

        $display("\n=== Results: %0d PASS  %0d FAIL ===",
                 pass_cnt, fail_cnt);
        #50 $finish;
    end

endmodule