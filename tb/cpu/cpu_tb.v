// ============================================================
// cpu_tb — alias for pipelined_cpu_tb
// Included for compatibility with the project file listing.
// Run pipelined_cpu_tb.v directly for full pipeline test.
// ============================================================
`timescale 1ns/1ps

// Re-use pipelined_cpu_tb as the full CPU test
// To simulate: iverilog -o sim/cpu_tb rtl/cpu/**/*.v rtl/cpu/*.v tb/cpu/pipelined_cpu_tb.v
// See scripts/run_all.sh for automation
