# Cache Architecture Notes

## Overview

| Parameter        | Value                        |
|-----------------|------------------------------|
| Type            | 2-way Set-Associative        |
| Write policy    | Write-Back                   |
| Replacement     | LRU (1-bit per set)          |
| Sets            | 256                          |
| Ways per set    | 2                            |
| Words per line  | 4 (16 bytes)                 |
| Total capacity  | 256 × 2 × 16B = **8 KB**    |
| Address width   | 32 bits                      |

---

## Address Breakdown (32-bit)

```
[31           12][11          4][3    2][1  0]
  TAG (20 bits)   SET (8 bits)  WORD   BYTE
                                (2b)   (ignored)
```

- **Tag**: 20 bits — identifies which memory block is in the cache
- **Set index**: 8 bits — selects one of 256 sets
- **Word offset**: 2 bits — selects one of 4 words in the line
- **Byte offset**: 2 bits — byte within word (not used at word-granularity interface)

---

## Cache Storage Arrays

```verilog
tag_array  [256 sets][2 ways]         // 20-bit tags
data_array [256 sets][2 ways][4 words] // 32-bit words
valid      [256 sets][2 ways]          // 1-bit valid flags
dirty      [256 sets][2 ways]          // 1-bit dirty flags (write-back)
lru        [256 sets]                  // 1-bit LRU per set
```

---

## FSM States

```
IDLE → TAG_CHECK → (HIT) → IDLE
                 → (MISS, clean victim) → MEM_FETCH → UPDATE → IDLE
                 → (MISS, dirty victim) → WRITE_BACK → MEM_FETCH → UPDATE → IDLE
```

| State       | Action |
|-------------|--------|
| IDLE        | Wait for CPU request (re or we) |
| TAG_CHECK   | Compare requested tag against both ways; determine hit/miss; select victim via LRU |
| WRITE_BACK  | Evict dirty victim line to main memory, 4 words one at a time |
| MEM_FETCH   | Fetch new cache line from main memory, 4 words into fill buffer |
| UPDATE      | Install fill buffer into victim way; apply pending CPU op; update LRU |

---

## Write-Back Policy

- On a **write hit**: Write to the cache line, set `dirty` bit. Do **not** write to memory.
- On a **write miss**: Fetch the line first (allocate), then write to the cache (write-allocate).
- On **eviction**: If `dirty == 1`, write the entire line back to memory before fetching the new line.

This minimises memory bus traffic compared to write-through.

---

## LRU Replacement

A single bit per set:
- `lru[set] = 0` → way 0 is LRU (will be evicted next)
- `lru[set] = 1` → way 1 is LRU

On any access (hit or fill):
- Update `lru[set]` to point to the **other** way (i.e., the accessed way becomes MRU).

---

## Hit/Miss Timing

| Event          | Cycles |
|----------------|--------|
| Hit (read/write) | 1 (combinational tag check + data read) |
| Cold miss (clean victim) | 1 (tag check) + 4 (fetch) + 1 (update) = ~6+ |
| Miss + dirty eviction   | 1 + 4 (write-back) + 4 (fetch) + 1 = ~10+ |

*Actual cycle count depends on `main_memory` latency (4-cycle default).*

---

## Integration with CPU

The cache controller drives `cpu_stall` high during misses. The pipelined CPU must hold its PC and pipeline registers when stalled. In the current SoC, the cache sits between the CPU's data memory interface and main memory.

---

## Key Design Choices

1. **Word-granularity interface**: CPU always accesses full words; byte enables are handled in `data_memory.v` for the CPU's local SRAM.
2. **Fill buffer**: Line data is accumulated in a local register array before being written atomically into the cache array — avoids partial-line installs.
3. **Write-allocate on miss**: Consistent with write-back; most real caches use this combination.
4. **Synchronous arrays**: All cache array updates on rising clock edge — synthesisable to SRAM macros.
