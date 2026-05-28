# Cache Architecture Notes

## Overview

The project implements a simplified write-back cache controller for a custom RISC-V style processor subsystem.

The cache is designed to reduce memory access latency by storing frequently accessed data locally and only accessing main memory during cache misses.

---

# Cache Organization

* 2-way set associative cache
* 4 cache sets
* 32-bit cache line size
* write-back policy
* Least Recently Used (LRU) replacement policy

---

# Address Breakdown

The 32-bit CPU address is divided into:

* Tag      : bits [31:6]
* Index    : bits [5:4]
* Offset   : bits [3:0]

The index selects the cache set while the tag identifies the cache line.

---

# Cache Components

## Data Array

Stores cached 32-bit data values.

## Tag Array

Stores address tags associated with cache lines.

## Valid Bits

Indicate whether a cache line contains valid data.

## Dirty Bits

Indicate whether cached data has been modified and must be written back to memory before replacement.

## LRU Bits

Track recently used ways for replacement decisions.

---

# Cache Operations

## Read Hit

If the requested address tag matches a valid cache line:

* data is returned immediately
* CPU ready signal is asserted
* LRU state is updated

---

## Read Miss

If no valid tag match exists:

* memory read request is generated
* cache enters MEM_READ state
* memory data is fetched
* cache line is refilled

---

## Write Hit

When writing to a valid cache line:

* cache data is updated
* dirty bit is set
* write-back occurs later during eviction

---

# Dirty Eviction

Before replacing a dirty cache line:

* old cache line is written back to memory
* WRITE_BACK FSM state is entered
* refill occurs after memory acknowledgement

---

# Cache FSM States

## IDLE

Normal cache operation state.

## MEM_READ

Waiting for memory response during cache miss handling.

## REFILL

Updating cache arrays using fetched memory data.

## WRITE_BACK

Writing dirty victim cache line back to memory before replacement.

---

# Verification Status

Verified using GTKWave simulations:

* cache hits
* cache misses
* cache refill
* dirty eviction
* LRU replacement behavior

---

# Future Improvements

Possible future enhancements:

* byte-addressable cache lines
* burst memory transactions
* non-blocking cache
* write buffers
* cache coherence support
* configurable associativity
