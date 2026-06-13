#!/bin/bash
# ============================================================
# run_all.sh — Compile and simulate all testbenches
# Usage: bash scripts/run_all.sh
# Requires: iverilog, vvp (Icarus Verilog)
# ============================================================

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM="$ROOT/sim"
RTL_CPU="$ROOT/rtl/cpu"
RTL_PIPE="$ROOT/rtl/cpu/pipeline"
RTL_CACHE="$ROOT/rtl/cache"
RTL_MEM="$ROOT/rtl/memory"
RTL_FIFO="$ROOT/rtl/fifo"
RTL_SOC="$ROOT/rtl/soc"
TB_CPU="$ROOT/tb/cpu"
TB_CACHE="$ROOT/tb/cache"
TB_FIFO="$ROOT/tb/fifo"
TB_SOC="$ROOT/tb/soc"

mkdir -p "$SIM"

PASS=0
FAIL=0

run_sim() {
    local NAME="$1"
    local OUT="$SIM/${NAME}"
    shift
    echo ""
    echo "──────────────────────────────────────────"
    echo "  Simulating: $NAME"
    echo "──────────────────────────────────────────"
    if iverilog -g2012 -o "$OUT" "$@" 2>&1; then
        if vvp "$OUT" 2>&1; then
            echo "  ✓ $NAME — OK"
            PASS=$((PASS+1))
        else
            echo "  ✗ $NAME — runtime error"
            FAIL=$((FAIL+1))
        fi
    else
        echo "  ✗ $NAME — compile error"
        FAIL=$((FAIL+1))
    fi
}

# ── ALU ────────────────────────────────────────────────────
run_sim alu_tb \
    $RTL_CPU/alu.v \
    $TB_CPU/alu_tb.v

# ── Register File ───────────────────────────────────────────
run_sim register_file_tb \
    $RTL_CPU/register_file.v \
    $TB_CPU/register_file_tb.v

# ── Immediate Generator ─────────────────────────────────────
run_sim immediate_generator_tb \
    $RTL_CPU/immediate_generator.v \
    $TB_CPU/immediate_generator_tb.v

# ── Control Unit ────────────────────────────────────────────
run_sim control_unit_tb \
    $RTL_CPU/control_unit.v \
    $TB_CPU/control_unit_tb.v

# ── Data Memory ─────────────────────────────────────────────
run_sim data_memory_tb \
    $RTL_CPU/data_memory.v \
    $TB_CPU/data_memory_tb.v

# ── Instruction Memory ──────────────────────────────────────
run_sim instruction_memory_tb \
    $RTL_CPU/instruction_memory.v \
    $TB_CPU/instruction_memory_tb.v

# ── IF/ID Register ──────────────────────────────────────────
run_sim if_id_tb \
    $RTL_PIPE/if_id.v \
    $TB_CPU/if_id_tb.v

# ── ID/EX Register ──────────────────────────────────────────
run_sim id_ex_tb \
    $RTL_PIPE/id_ex.v \
    $TB_CPU/id_ex_tb.v

# ── EX/MEM Register ─────────────────────────────────────────
run_sim ex_mem_tb \
    $RTL_PIPE/ex_mem.v \
    $TB_CPU/ex_mem_tb.v

# ── MEM/WB Register ─────────────────────────────────────────
run_sim mem_wb_tb \
    $RTL_PIPE/mem_wb.v \
    $TB_CPU/mem_wb_tb.v

# ── Hazard Detection ────────────────────────────────────────
run_sim hazard_detection_unit_tb \
    $RTL_PIPE/hazard_detection_unit.v \
    $TB_CPU/hazard_detection_unit_tb.v

# ── Forwarding Unit ─────────────────────────────────────────
run_sim forwarding_unit_tb \
    $RTL_PIPE/forwarding_unit.v \
    $TB_CPU/forwarding_unit_tb.v

# ── Full Pipelined CPU ──────────────────────────────────────
run_sim pipelined_cpu_tb \
    $RTL_CPU/alu.v \
    $RTL_CPU/register_file.v \
    $RTL_CPU/control_unit.v \
    $RTL_CPU/immediate_generator.v \
    $RTL_CPU/instruction_memory.v \
    $RTL_CPU/data_memory.v \
    $RTL_PIPE/if_id.v \
    $RTL_PIPE/id_ex.v \
    $RTL_PIPE/ex_mem.v \
    $RTL_PIPE/mem_wb.v \
    $RTL_PIPE/hazard_detection_unit.v \
    $RTL_PIPE/forwarding_unit.v \
    $RTL_CPU/pipelined_datapath.v \
    $RTL_CPU/cpu_top.v \
    $TB_CPU/pipelined_cpu_tb.v

# ── Cache Controller ────────────────────────────────────────
run_sim cache_controller_tb \
    $RTL_CACHE/cache_controller.v \
    $TB_CACHE/cache_controller_tb.v

# ── Cache System ────────────────────────────────────────────
run_sim cache_system_tb \
    $RTL_CACHE/cache_controller.v \
    $RTL_MEM/main_memory.v \
    $RTL_CACHE/cache_system.v \
    $TB_CACHE/cache_system_tb.v

# ── CDC FIFO ────────────────────────────────────────────────
run_sim cdc_fifo_tb \
    $RTL_FIFO/cdc_fifo.v \
    $TB_FIFO/cdc_fifo_tb.v

echo ""
echo "════════════════════════════════════════════"
echo "  SIMULATION SUMMARY"
echo "  PASS: $PASS   FAIL: $FAIL"
echo "════════════════════════════════════════════"
echo ""
echo "VCD files in: $SIM/"
echo "Open with:    gtkwave sim/<name>.vcd"
