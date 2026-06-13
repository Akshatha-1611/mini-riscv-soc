// ============================================================
// Cache Controller — 2-way Set-Associative, Write-Back, LRU
//
// Simulation parameters (small for Icarus):
//   NUM_SETS  = 4   → 4 sets  (use 256 for synthesis)
//   LINE_WORDS= 4   → 4 words per line (16 bytes)
//   Total sim capacity: 4 × 2 × 16B = 128 bytes
//
// Address breakdown (NUM_SETS=4):
//   [31:6]  tag   (26 bits)
//   [5:4]   set   ( 2 bits, log2(4))
//   [3:2]   word  ( 2 bits)
//   [1:0]   byte offset (ignored)
//
// To scale for synthesis: increase NUM_SETS and SET_BITS,
// adjust tag/set slices accordingly.
// ============================================================
`timescale 1ns/1ps

module cache_controller (
    input  wire        clk,
    input  wire        rst_n,

    // CPU interface
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_we,
    input  wire        cpu_re,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,
    output reg         cpu_stall,

    // Memory interface
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg         mem_we,
    output reg         mem_re,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);

    // ── Address breakdown ────────────────────────────────────
    // Fixed for NUM_SETS=4: set=[5:4], word=[3:2], byte=[1:0]
    localparam NUM_SETS  = 4;
    localparam TAG_BITS  = 26;  // 32 - 2(set) - 2(word) - 2(byte)
    localparam SET_BITS  = 2;   // log2(4)

    wire [TAG_BITS-1:0] req_tag  = cpu_addr[31:6];
    wire [SET_BITS-1:0] req_set  = cpu_addr[5:4];
    wire [1:0]          req_word = cpu_addr[3:2];

    // ── Storage (tiny: 4 sets × 2 ways × 4 words) ───────────
    reg [TAG_BITS-1:0] tag_arr  [0:3][0:1];   // [set][way]
    reg [31:0]         data_arr [0:3][0:1][0:3]; // [set][way][word]
    reg                valid    [0:3][0:1];
    reg                dirty    [0:3][0:1];
    reg                lru      [0:3]; // 0=way0 LRU, 1=way1 LRU

    // ── FSM states ───────────────────────────────────────────
    localparam S_IDLE   = 3'd0;
    localparam S_CHECK  = 3'd1;
    localparam S_WB     = 3'd2;   // write-back dirty victim
    localparam S_FETCH  = 3'd3;   // fetch new line from memory
    localparam S_UPDATE = 3'd4;   // install line, serve CPU

    reg [2:0] state;
    reg [1:0] word_cnt;   // counts 0→3 for WB and FETCH
    reg       victim_way; // which way is being evicted

    // Latch the CPU request so it stays stable across multi-cycle ops
    reg [TAG_BITS-1:0] r_tag;
    reg [SET_BITS-1:0] r_set;
    reg [1:0]          r_word;
    reg [31:0]         r_wdata;
    reg                r_we;

    // Fill buffer: one cache line from memory
    reg [31:0] fill_buf [0:3];

    integer s, w;
    initial begin
        state      = S_IDLE;
        word_cnt   = 0;
        victim_way = 0;
        for (s = 0; s < 4; s = s + 1) begin
            lru[s] = 0;
            for (w = 0; w < 2; w = w + 1) begin
                valid   [s][w] = 0;
                dirty   [s][w] = 0;
                tag_arr [s][w] = 0;
                data_arr[s][w][0] = 32'hDEAD_0000 | (s*8+w*4+0);
                data_arr[s][w][1] = 32'hDEAD_0000 | (s*8+w*4+1);
                data_arr[s][w][2] = 32'hDEAD_0000 | (s*8+w*4+2);
                data_arr[s][w][3] = 32'hDEAD_0000 | (s*8+w*4+3);
            end
        end
    end

    // ── Hit detection (combinational on registered request) ──
    wire hit0 = valid[r_set][0] && (tag_arr[r_set][0] == r_tag);
    wire hit1 = valid[r_set][1] && (tag_arr[r_set][1] == r_tag);
    wire hit  = hit0 | hit1;
    wire hit_way_sel = hit1; // 0→way0, 1→way1

    // ── Main FSM ─────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            cpu_ready  <= 0; cpu_stall <= 0; cpu_rdata <= 0;
            mem_addr   <= 0; mem_wdata <= 0;
            mem_we     <= 0; mem_re    <= 0;
            word_cnt   <= 0; victim_way<= 0;
            r_tag<=0; r_set<=0; r_word<=0; r_wdata<=0; r_we<=0;
        end else begin
            cpu_ready <= 0; // default: deassert every cycle
            mem_we    <= 0;
            mem_re    <= 0;

            case (state)

            // ── IDLE ─────────────────────────────────────────
            S_IDLE: begin
                cpu_stall <= 0;
                if (cpu_re || cpu_we) begin
                    // Latch request — addr/data may change next cycle
                    r_tag   <= cpu_addr[31:6];
                    r_set   <= cpu_addr[5:4];
                    r_word  <= cpu_addr[3:2];
                    r_wdata <= cpu_wdata;
                    r_we    <= cpu_we;
                    state   <= S_CHECK;
                end
            end

            // ── TAG CHECK ────────────────────────────────────
            S_CHECK: begin
                if (hit) begin
                    // HIT — serve in this cycle
                    if (!r_we)
                        cpu_rdata <= data_arr[r_set][hit_way_sel][r_word];
                    else begin
                        data_arr[r_set][hit_way_sel][r_word] <= r_wdata;
                        dirty[r_set][hit_way_sel]            <= 1;
                    end
                    lru[r_set] <= ~hit_way_sel; // hit way → MRU
                    cpu_ready  <= 1;
                    cpu_stall  <= 0;
                    state      <= S_IDLE;

                end else begin
                    // MISS — choose victim, start eviction or fetch
                    cpu_stall  <= 1;
                    victim_way <= lru[r_set]; // LRU way is evicted
                    word_cnt   <= 0;

                    if (dirty[r_set][lru[r_set]]) begin
                        // Dirty victim → write it back first
                        state <= S_WB;
                    end else begin
                        // Clean victim → go straight to fetch
                        mem_addr <= {r_tag, r_set, 2'b00, 2'b00};
                        mem_re   <= 1;
                        state    <= S_FETCH;
                    end
                end
            end

            // ── WRITE-BACK ───────────────────────────────────
            // One word per clock when mem_ready is high.
            // We assert mem_we the same cycle we present the data.
            S_WB: begin
                // Always drive the current word onto the bus
                mem_addr  <= {tag_arr[r_set][victim_way],
                              r_set, word_cnt, 2'b00};
                mem_wdata <= data_arr[r_set][victim_way][word_cnt];
                mem_we    <= 1;

                if (mem_ready) begin
                    if (word_cnt == 2'd3) begin
                        // All 4 words written — mark clean, start fetch
                        dirty[r_set][victim_way] <= 0;
                        word_cnt <= 0;
                        mem_addr <= {r_tag, r_set, 2'b00, 2'b00};
                        mem_re   <= 1;
                        state    <= S_FETCH;
                    end else begin
                        word_cnt <= word_cnt + 1;
                    end
                end
            end

            // ── MEM FETCH ────────────────────────────────────
            // Receive one word per clock when mem_ready is high.
            S_FETCH: begin
                mem_addr <= {r_tag, r_set, word_cnt, 2'b00};
                mem_re   <= 1;

                if (mem_ready) begin
                    fill_buf[word_cnt] <= mem_rdata;
                    if (word_cnt == 2'd3) begin
                        mem_re <= 0;
                        state  <= S_UPDATE;
                    end else begin
                        word_cnt <= word_cnt + 1;
                    end
                end
            end

            // ── UPDATE ───────────────────────────────────────
            // Install fill buffer, apply pending CPU op, done.
            S_UPDATE: begin
                data_arr[r_set][victim_way][0] <= fill_buf[0];
                data_arr[r_set][victim_way][1] <= fill_buf[1];
                data_arr[r_set][victim_way][2] <= fill_buf[2];
                data_arr[r_set][victim_way][3] <= fill_buf[3];
                tag_arr [r_set][victim_way]    <= r_tag;
                valid   [r_set][victim_way]    <= 1;
                dirty   [r_set][victim_way]    <= 0;

                if (!r_we)
                    cpu_rdata <= fill_buf[r_word];
                else begin
                    data_arr[r_set][victim_way][r_word] <= r_wdata;
                    dirty[r_set][victim_way]            <= 1;
                end

                lru[r_set] <= ~victim_way; // installed way → MRU
                cpu_ready  <= 1;
                cpu_stall  <= 0;
                state      <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule