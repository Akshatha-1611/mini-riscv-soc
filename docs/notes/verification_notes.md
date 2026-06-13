# Verification Notes

## Test Strategy

### Unit Tests (bottom-up)

| Module | Testbench | Key Scenarios |
|--------|-----------|--------------|
| `alu` | `alu_tb.v` | All 12 operations, overflow, zero flag |
| `register_file` | `register_file_tb.v` | Read/write, x0 hardwired, reset |
| `immediate_generator` | `immediate_generator_tb.v` | All 5 formats (I/S/B/U/J), sign extension |
| `control_unit` | `control_unit_tb.v` | All opcode types → control signal correctness |
| `data_memory` | `data_memory_tb.v` | LB/LBU, LH/LHU, LW, SB, SH, SW |
| `instruction_memory` | `instruction_memory_tb.v` | Sequential fetch |
| `if_id` | `if_id_tb.v` | Pass-through, stall hold, flush → NOP |
| `id_ex` | `id_ex_tb.v` | Normal latch, flush to bubble |
| `ex_mem` | `ex_mem_tb.v` | Normal latch, reset |
| `mem_wb` | `mem_wb_tb.v` | Load path (mem_to_reg=1), ALU path |
| `hazard_detection_unit` | `hazard_detection_unit_tb.v` | Load-use RS1, load-use RS2, x0 no-stall, branch flush, jump flush |
| `forwarding_unit` | `forwarding_unit_tb.v` | No-fwd, EX/MEM fwd A&B, MEM/WB fwd A&B, priority, x0 no-fwd |

### Integration Tests

| Testbench | Tests |
|-----------|-------|
| `pipelined_cpu_tb.v` | R-type chain, load-store, forwarding, load-use stall, BEQ taken, SLTI |
| `cache_controller_tb.v` | Cold miss+fill, read hit, write hit (write-back dirty), dirty eviction, LRU |
| `cache_system_tb.v` | Write-read-back, full cache line writes, conflict miss |
| `cdc_fifo_tb.v` | Empty/full flags, single push/pop, burst fill+drain, simultaneous push/pop, different clocks |
| `soc_tb.v` | Full SoC boot + run |

---

## Waveforms to Capture (for `docs/waveforms/`)

Run each simulation, open in GTKWave, zoom to the interesting region, and screenshot.

### 1. `pipeline_forwarding.png`
**Testbench**: `pipelined_cpu_tb.v`  
**Signals to show**: `clk`, `if_id.id_instr`, `id_ex.rs1_data_out`, `forward_a[1:0]`, `alu_op_a`, `alu_result`, `wb_rd`, `wb_data`  
**What to capture**: The `ADD x3,x1,x2` → `SUB x4,x3,x1` sequence showing `forward_a=2'b10` (EX→EX forward) on the SUB instruction.

### 2. `pipeline_load_use_stall.png`
**Testbench**: `pipelined_cpu_tb.v`  
**Signals to show**: `clk`, `pc`, `if_id.id_instr`, `id_ex.mem_read_out`, `hazard.pc_write`, `hazard.id_ex_flush`, `hazard.if_id_write`  
**What to capture**: The `LW x6` → `ADD x7,x6,x1` load-use stall — one cycle where `pc_write=0`, `if_id_write=0`, `id_ex_flush=1`.

### 3. `pipeline_branch_taken.png`
**Testbench**: `pipelined_cpu_tb.v`  
**Signals to show**: `clk`, `pc`, `branch_taken`, `if_id_flush`, `id_ex_flush`  
**What to capture**: The `BEQ` instruction taken — PC jumps to target, two NOP bubbles inserted.

### 4. `dirty_eviction_waveform.png` *(already in project)*
**Testbench**: `cache_controller_tb.v`  
**Signals to show**: `clk`, `cpu_addr`, `cpu_re/we`, `cpu_stall`, `cpu_ready`, `dut.state[2:0]`, `mem_addr`, `mem_we`, `mem_wdata`  
**What to capture**: State machine going IDLE → TAG_CHECK → WRITE_BACK (4 mem_we pulses) → MEM_FETCH → UPDATE → IDLE, with `cpu_stall` high throughout.

### 5. `cache_hit_miss.png`
**Testbench**: `cache_controller_tb.v`  
**Signals to show**: `clk`, `cpu_addr`, `cpu_re`, `cpu_rdata`, `cpu_ready`, `cpu_stall`, `dut.state`  
**What to capture**: First access (MISS — multi-cycle stall), second access to same line (HIT — 1 cycle, no stall).

### 6. `cdc_fifo_gray_code.png`
**Testbench**: `cdc_fifo_tb.v`  
**Signals to show**: `wr_clk`, `rd_clk`, `wr_data`, `wr_en`, `full`, `wr_ptr_gray`, `wr_ptr_gray_s1_rd`, `wr_ptr_gray_s2_rd`, `empty`, `rd_data`, `rd_en`, `rd_ptr_gray`  
**What to capture**: A write on `wr_clk`, then 2-cycle synchronization delay before `empty` de-asserts on `rd_clk`.

### 7. `cdc_fifo_full_empty.png`
**Testbench**: `cdc_fifo_tb.v`  
**What to capture**: Burst write of 16 entries → `full` asserts; subsequent burst read → `empty` asserts.

---

## How to Take Screenshots with GTKWave

```bash
# 1. Run simulation to generate VCD
bash scripts/sim.sh pipelined_cpu

# 2. Open GTKWave with pre-configured save file
gtkwave sim/pipelined_cpu_tb.vcd sim/pipelined_cpu.gtkw

# 3. In GTKWave:
#    - Use Time → Zoom to Fit  (Ctrl+Shift+F)
#    - Drag signal names from SST to signals panel
#    - Zoom into the region of interest with scroll wheel
#    - File → Print → Save as PNG
#    - Save to docs/waveforms/<name>.png
```

---

## Simulation Commands

```bash
# Run all tests
bash scripts/run_all.sh

# Run single module
bash scripts/sim.sh alu
bash scripts/sim.sh pipelined_cpu
bash scripts/sim.sh cache_controller
bash scripts/sim.sh cdc_fifo

# View waveform
gtkwave sim/alu_tb.vcd
gtkwave sim/pipelined_cpu_tb.vcd sim/pipelined_cpu.gtkw
gtkwave sim/cdc_fifo_tb.vcd      sim/cdc_fifo.gtkw
gtkwave sim/cache_controller_tb.vcd sim/cache_controller.gtkw
```
