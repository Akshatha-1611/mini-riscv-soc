# Mini RISC-V SoC

A fully synthesisable, industry-quality RISC-V System-on-Chip implemented in Verilog.  
Designed as a portfolio project for core VLSI roles (Intel, AMD, NVIDIA, Qualcomm, etc.).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     mini_riscv_soc                          │
│                                                             │
│  ┌─────────────┐    ┌───────────────┐    ┌──────────────┐  │
│  │  RISC-V CPU │───▶│  Cache System │───▶│  CDC FIFO    │  │
│  │  5-stage    │◀───│  2-way SA     │◀───│  (Dual-clock)│  │
│  │  pipeline   │    │  Write-back   │    └──────┬───────┘  │
│  └─────────────┘    │  LRU          │           │          │
│                     └───────────────┘    ┌──────▼───────┐  │
│                                          │  Main Memory │  │
│                                          │  (mem_clk)   │  │
│                                          └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. RISC-V CPU (`rtl/cpu/`)

- **ISA**: RV32I base integer (R/I/S/B/U/J-type)
- **Pipeline**: Classic 5-stage (IF → ID → EX → MEM → WB)
- **Hazards**: Full data hazard resolution via forwarding + load-use stall
- **Control hazards**: Branch resolved in EX, 2-cycle flush penalty
- **Modules**: `alu`, `register_file`, `control_unit`, `immediate_generator`, `instruction_memory`, `data_memory`, `pipelined_datapath`, `cpu_top`
- **Pipeline registers**: `if_id`, `id_ex`, `ex_mem`, `mem_wb`
- **Hazard logic**: `hazard_detection_unit`, `forwarding_unit`

### 2. Cache (`rtl/cache/`)

- **Type**: 2-way Set-Associative
- **Size**: 8 KB (256 sets × 2 ways × 4 words × 4 bytes)
- **Write policy**: Write-back with write-allocate
- **Replacement**: LRU (1-bit per set)
- **Miss handling**: FSM (IDLE → TAG_CHECK → WRITE_BACK → MEM_FETCH → UPDATE)
- **Modules**: `cache_controller`, `cache_system`

### 3. CDC FIFO (`rtl/fifo/`)

- **Type**: Dual-clock asynchronous FIFO
- **Depth**: 16 entries × 32 bits
- **CDC method**: Gray-code pointers + 2-FF synchronizer
- **Flags**: `full` (write domain), `empty` (read domain)
- **Module**: `cdc_fifo`

### 4. Main Memory (`rtl/memory/`)

- 64 KB word-addressed SRAM model
- Configurable access latency (default: 4 cycles)
- **Module**: `main_memory`

---

## Repository Structure

```
mini-riscv-soc/
├── rtl/
│   ├── cpu/
│   │   ├── pipeline/          # Pipeline registers + hazard/forwarding units
│   │   ├── alu.v
│   │   ├── control_unit.v
│   │   ├── register_file.v
│   │   ├── immediate_generator.v
│   │   ├── instruction_memory.v
│   │   ├── data_memory.v
│   │   ├── pipelined_datapath.v
│   │   └── cpu_top.v
│   ├── cache/
│   │   ├── cache_controller.v
│   │   └── cache_system.v
│   ├── fifo/
│   │   └── cdc_fifo.v
│   ├── memory/
│   │   └── main_memory.v
│   └── soc/
│       └── mini_riscv_soc.v
├── tb/
│   ├── cpu/                   # Unit testbenches for every CPU module
│   ├── cache/                 # Cache testbenches
│   ├── fifo/                  # CDC FIFO testbench
│   └── soc/                   # SoC integration testbench
├── sim/                       # VCD outputs + GTKWave save files
├── docs/
│   ├── notes/                 # Architecture notes (pipeline, cache, CDC)
│   ├── diagrams/
│   └── waveforms/             # Screenshot PNGs for interviews
└── scripts/
    ├── run_all.sh             # Run all simulations
    └── sim.sh                 # Run a single module
```

---

## Quick Start

### Prerequisites

```bash
# Ubuntu / Debian
sudo apt install iverilog gtkwave

# macOS
brew install icarus-verilog gtkwave
```

### Run All Simulations

```bash
git clone https://github.com/your-username/mini-riscv-soc.git
cd mini-riscv-soc
chmod +x scripts/*.sh
bash scripts/run_all.sh
```

### Run a Single Module

```bash
bash scripts/sim.sh alu
bash scripts/sim.sh pipelined_cpu
bash scripts/sim.sh cache_controller
bash scripts/sim.sh cdc_fifo
```

### View Waveforms

```bash
# With pre-configured signal groups
gtkwave sim/pipelined_cpu_tb.vcd    sim/pipelined_cpu.gtkw
gtkwave sim/cache_controller_tb.vcd sim/cache_controller.gtkw
gtkwave sim/cdc_fifo_tb.vcd         sim/cdc_fifo.gtkw
```

---

## Waveforms

Key waveform screenshots are in `docs/waveforms/`:

| File | Shows |
|------|-------|
| `pipeline_forwarding.png`      | EX→EX forwarding (forward_a=10) during ADD→SUB chain |
| `pipeline_load_use_stall.png`  | 1-cycle stall on LW→ADD load-use hazard |
| `pipeline_branch_taken.png`    | BEQ taken: PC redirect + 2-cycle flush |
| `dirty_eviction_waveform.png`  | Cache FSM: WRITE_BACK → MEM_FETCH → UPDATE |
| `cache_hit_miss.png`           | Miss (multi-cycle stall) then hit (1 cycle) |
| `cdc_fifo_gray_code.png`       | Gray-code pointer sync across clock domains |
| `cdc_fifo_full_empty.png`      | FIFO full/empty flags during burst transfer |

---

## Design Highlights for Interviews

| Topic | Where |
|-------|-------|
| RAW hazard forwarding (EX→EX, MEM→EX) | `forwarding_unit.v`, `pipelined_datapath.v` |
| Load-use stall (1 bubble) | `hazard_detection_unit.v` |
| Control hazard flush | `hazard_detection_unit.v` + `if_id.v`, `id_ex.v` |
| Write-back dirty eviction FSM | `cache_controller.v` (WRITE_BACK state) |
| LRU replacement | `cache_controller.v` (lru[] array) |
| Gray-code CDC | `cdc_fifo.v` (bin2gray function + 2-FF sync) |
| Full/empty flag generation | `cdc_fifo.v` (MSB-inversion trick) |

---

## License

MIT — free for personal and educational use.
