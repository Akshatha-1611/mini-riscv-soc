# RISC-V 5-Stage Pipeline Notes

## Pipeline Stages

```
IF → ID → EX → MEM → WB
```

| Stage | Module | Function |
|-------|--------|----------|
| IF  | `pipelined_datapath` (PC logic) | Fetch instruction from `instruction_memory` using PC |
| ID  | `control_unit`, `register_file`, `immediate_generator` | Decode instruction, read registers, generate immediate |
| EX  | `alu`, `forwarding_unit` | Compute ALU result, resolve branches |
| MEM | `data_memory` | Load or store to data memory |
| WB  | `pipelined_datapath` (mux) | Write result back to register file |

---

## Pipeline Registers

| Register | Module | Holds |
|----------|--------|-------|
| IF/ID    | `if_id.v`   | PC, instruction |
| ID/EX    | `id_ex.v`   | PC, control signals, rs1/rs2 data, imm, register addresses |
| EX/MEM   | `ex_mem.v`  | ALU result, rs2 data (store), rd, PC+4, control signals |
| MEM/WB   | `mem_wb.v`  | Memory read data, ALU result, rd, PC+4, control signals |

---

## Hazard Handling

### Data Hazards

**RAW (Read After Write)** — solved by forwarding:
- **EX→EX forwarding**: When EX/MEM.rd == ID/EX.rs1 (or rs2), forward `alu_result` from EX/MEM to EX ALU input.
- **MEM→EX forwarding**: When MEM/WB.rd == ID/EX.rs1 (or rs2), forward `wb_data` from MEM/WB to EX ALU input.
- **Load-use hazard** (cannot be forwarded): When a `LW` is in EX and the next instruction reads the loaded register:
  - Stall: freeze PC and IF/ID for 1 cycle
  - Insert NOP bubble into ID/EX

Forwarding priority (EX/MEM wins over MEM/WB):
```
if (EX/MEM.RegWrite && EX/MEM.Rd == RS) → forward from EX/MEM.ALUResult
elif (MEM/WB.RegWrite && MEM/WB.Rd == RS) → forward from MEM/WB.WBData
else → use register file output
```

### Control Hazards

**Branch/Jump** resolved at the end of EX stage:
- On taken branch or jump: flush IF/ID and ID/EX (insert 2 NOPs)
- Penalty: 2 wasted cycles per taken branch/jump

**Branch prediction**: Static "not taken" — simplest and correct for interview-level RTL.

---

## Instruction Support

| Format  | Instructions |
|---------|-------------|
| R-type  | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| I-type  | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, LW, LH, LB, LHU, LBU, JALR |
| S-type  | SW, SH, SB |
| B-type  | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| U-type  | LUI, AUIPC |
| J-type  | JAL |

---

## ALU Control Encoding

| Code   | Operation | Used by |
|--------|-----------|---------|
| 4'b0000 | ADD  | ADD, ADDI, LW, SW, AUIPC |
| 4'b0001 | SUB  | SUB, BEQ, BNE |
| 4'b0010 | AND  | AND, ANDI |
| 4'b0011 | OR   | OR, ORI |
| 4'b0100 | XOR  | XOR, XORI |
| 4'b0101 | SLL  | SLL, SLLI |
| 4'b0110 | SRL  | SRL, SRLI |
| 4'b0111 | SRA  | SRA, SRAI |
| 4'b1000 | SLT  | SLT, SLTI, BLT, BGE |
| 4'b1001 | SLTU | SLTU, SLTIU, BLTU, BGEU |
| 4'b1010 | LUI  | LUI (pass B) |
| 4'b1011 | PASS | JAL (pass imm) |

---

## Key Design Decisions

1. **Single-cycle memory** (data_memory): For simplicity; in the full SoC, cache introduces multi-cycle latency via `cpu_stall`.
2. **Branch resolved in EX**: Minimises branch penalty to 2 cycles; industry designs often push it to ID (1 cycle penalty) with more hardware.
3. **x0 hardwired**: Register file prevents writes to register 0 and always returns 0.
4. **Synchronous instruction memory**: 1-cycle fetch latency; PC advances on same clock.
