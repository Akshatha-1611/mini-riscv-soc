# Pipeline Notes

## Overview

The processor datapath is implemented using a pipelined architecture to improve instruction throughput.

The design follows a simplified RISC-V style execution flow.

---

# Pipeline Stages

## Instruction Fetch (IF)

* fetches instruction from instruction memory
* updates program counter (PC)

---

## Instruction Decode (ID)

* decodes instruction fields
* reads register operands
* generates control signals
* generates immediate values

---

## Execute (EX)

* performs ALU operations
* calculates branch targets
* evaluates arithmetic and logical operations

---

## Memory Access (MEM)

* interfaces with cache and memory subsystem
* performs load/store operations

---

## Write Back (WB)

* writes execution or memory results back into register file

---

# Pipeline Registers

The processor currently includes:

* IF/ID pipeline register
* ID/EX pipeline register

Additional pipeline registers may be added later.

---

# Hazard Handling

Current and planned hazard handling features:

* data hazard detection
* pipeline stalling
* forwarding logic
* cache miss stalls
* branch flush support

---

# Datapath Components

Implemented modules include:

* ALU
* register file
* immediate generator
* instruction memory
* data memory
* control unit
* pipeline registers

---

# Verification

Pipeline behavior verified using:

* GTKWave waveform inspection
* instruction propagation tracking
* register monitoring
* control signal verification

---

# Planned Enhancements

Future pipeline improvements:

* forwarding unit
* branch prediction
* branch flush logic
* deeper pipeline stages
* superscalar extensions
