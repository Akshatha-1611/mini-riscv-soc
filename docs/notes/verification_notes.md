# Verification Notes

## Verification Methodology

RTL modules are verified using:

* Icarus Verilog
* custom Verilog testbenches
* GTKWave waveform analysis

---

# Verified Modules

## ALU

Verified operations:

* ADD
* SUB
* AND
* OR
* XOR
* zero flag generation

---

## Register File

Verified:

* register write operations
* dual read ports
* reset behavior

---

## Immediate Generator

Verified:

* immediate extraction
* sign extension

---

## Pipeline Registers

Verified:

* IF/ID propagation
* ID/EX propagation
* reset behavior
* write enable functionality

---

## Cache Controller

Verified:

* cache hits
* cache misses
* memory refill
* dirty eviction
* write-back behavior
* LRU replacement

---

# Dirty Eviction Verification

Observed behavior:

1. dirty victim detected
2. WRITE_BACK state entered
3. memory write asserted
4. memory acknowledgement received
5. memory refill initiated
6. cache line updated successfully

---

# Waveform Verification

Important waveform captures stored in:

* docs/waveforms/

---

# Known Limitations

Current limitations:

* simplified memory timing
* no branch prediction
* no forwarding unit yet
* limited instruction set support

---

# Planned Verification Extensions

Future verification goals:

* randomized testbenches
* constrained random testing
* assertion-based verification
* functional coverage
* regression automation
