# CDC FIFO Architecture Notes

## Overview

| Parameter    | Value                   |
|-------------|-------------------------|
| Type         | Dual-Clock Async FIFO   |
| Depth        | 16 entries (power of 2) |
| Data width   | 32 bits (configurable)  |
| Pointer width| 5 bits (log2(16) + 1)   |
| CDC method   | Gray-code + 2-FF sync   |

---

## Architecture

```
  WR_CLK domain                   RD_CLK domain
  ─────────────────────────────────────────────────────
  wr_en ──→ [Write Logic]                [Read Logic] ──→ rd_data
  wr_data ─→ [FIFO Memory]──────────────→             ──→ empty
  full ←──── [Full Logic]   2-FF Sync    [Empty Logic]
              wr_ptr_gray ──────────────→ wr_ptr_gray_s2_rd
              rd_ptr_gray ←────────────── rd_ptr_gray_s2_wr
                          ←── 2-FF Sync
```

---

## Why Gray Code?

Binary pointers can have multiple bits change simultaneously (e.g., 0111 → 1000). When crossing clock domains, metastability can cause the receiver to see an intermediate, invalid value.

Gray code changes **only 1 bit at a time**, so even if the synchronizer samples during a transition, the received value is either the old or new pointer — never a garbage intermediate.

### Binary vs Gray Code Example
```
Binary:  0 → 1 → 2 → 3 → 4
         000  001  010  011  100   ← multiple bits change at 3→4

Gray:    0 → 1 → 2 → 3 → 4
         000  001  011  010  110   ← always 1 bit changes
```

### Binary-to-Gray Conversion
```
gray = bin ^ (bin >> 1)
```

---

## Pointer Scheme (extra MSB for full/empty distinction)

With `DEPTH=16` and `PTR_WIDTH=4`, pointers are **5 bits** wide. The MSB distinguishes between "same lap" (empty) and "opposite lap" (full):

- **Empty**: `rd_ptr_gray == wr_ptr_gray_s2_rd` (both pointers equal in read domain)
- **Full**: `wr_ptr_gray == {~rd_ptr_gray_s2_wr[MSB:MSB-1], rd_ptr_gray_s2_wr[MSB-2:0]}` (MSBs inverted, rest equal)

---

## 2-FF Synchronizer

Each pointer is synchronized into the other domain using two cascaded flip-flops:

```
                   FF1              FF2
wr_ptr_gray ──→ [D Q]──→[D Q]──→ wr_ptr_gray_s2_rd (in rd_clk domain)
               rd_clk  rd_clk
```

This reduces metastability probability to an astronomically low level (MTBF > years for typical designs).

---

## Key Properties

1. **No combinational paths cross clock domains** — only registered signals cross via 2-FF sync.
2. **Conservative empty/full**: Due to sync latency, the FIFO may appear full slightly before it actually is, and empty slightly before it is. This is **safe** — it prevents overflow/underflow.
3. **Power of 2 depth required**: Ensures the binary-to-Gray conversion wraps cleanly (MSB flip correctly indicates wrap-around).

---

## SoC Integration

The CDC FIFO bridges the CPU/cache clock domain (100 MHz) and the main memory clock domain (66 MHz):

```
CPU (100 MHz) ──→ cache_controller ──→ [Request FIFO 64-bit]  ──→ main_memory (66 MHz)
              ←── cache_controller ←── [Response FIFO 32-bit] ←──
```

Request FIFO carries `{addr[31:0], wdata[31:0]}` (64-bit).
Response FIFO carries `rdata[31:0]` (32-bit).
