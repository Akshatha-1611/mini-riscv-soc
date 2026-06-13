#!/bin/bash
# ============================================================
# sim.sh — Compile and simulate a single module quickly
# Usage: bash scripts/sim.sh <module_name>
# Example: bash scripts/sim.sh alu
#          bash scripts/sim.sh pipelined_cpu
#          bash scripts/sim.sh cdc_fifo
#          bash scripts/sim.sh cache_controller
# ============================================================

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM="$ROOT/sim"
mkdir -p "$SIM"

MODULE="${1:-alu}"

RTL_CPU="$ROOT/rtl/cpu"
RTL_PIPE="$ROOT/rtl/cpu/pipeline"
RTL_CACHE="$ROOT/rtl/cache"
RTL_MEM="$ROOT/rtl/memory"
RTL_FIFO="$ROOT/rtl/fifo"

compile_and_run() {
    echo "Compiling $MODULE..."
    if iverilog -g2012 -o "$SIM/${MODULE}_tb" "$@"; then
        echo "Running simulation..."
        vvp "$SIM/${MODULE}_tb"
        echo ""
        echo "VCD saved. Open with:"
        echo "  gtkwave $SIM/${MODULE}_tb.vcd"
    else
        echo "Compilation failed."
        exit 1
    fi
}

case "$MODULE" in
    alu)
        compile_and_run $RTL_CPU/alu.v $ROOT/tb/cpu/alu_tb.v ;;
    register_file)
        compile_and_run $RTL_CPU/register_file.v $ROOT/tb/cpu/register_file_tb.v ;;
    immediate_generator)
        compile_and_run $RTL_CPU/immediate_generator.v $ROOT/tb/cpu/immediate_generator_tb.v ;;
    control_unit)
        compile_and_run $RTL_CPU/control_unit.v $ROOT/tb/cpu/control_unit_tb.v ;;
    data_memory)
        compile_and_run $RTL_CPU/data_memory.v $ROOT/tb/cpu/data_memory_tb.v ;;
    instruction_memory)
        compile_and_run $RTL_CPU/instruction_memory.v $ROOT/tb/cpu/instruction_memory_tb.v ;;
    if_id)
        compile_and_run $RTL_PIPE/if_id.v $ROOT/tb/cpu/if_id_tb.v ;;
    id_ex)
        compile_and_run $RTL_PIPE/id_ex.v $ROOT/tb/cpu/id_ex_tb.v ;;
    ex_mem)
        compile_and_run $RTL_PIPE/ex_mem.v $ROOT/tb/cpu/ex_mem_tb.v ;;
    mem_wb)
        compile_and_run $RTL_PIPE/mem_wb.v $ROOT/tb/cpu/mem_wb_tb.v ;;
    hazard_detection_unit)
        compile_and_run $RTL_PIPE/hazard_detection_unit.v $ROOT/tb/cpu/hazard_detection_unit_tb.v ;;
    forwarding_unit)
        compile_and_run $RTL_PIPE/forwarding_unit.v $ROOT/tb/cpu/forwarding_unit_tb.v ;;
    pipelined_cpu|cpu)
        compile_and_run \
            $RTL_CPU/alu.v $RTL_CPU/register_file.v $RTL_CPU/control_unit.v \
            $RTL_CPU/immediate_generator.v $RTL_CPU/instruction_memory.v \
            $RTL_CPU/data_memory.v \
            $RTL_PIPE/if_id.v $RTL_PIPE/id_ex.v $RTL_PIPE/ex_mem.v $RTL_PIPE/mem_wb.v \
            $RTL_PIPE/hazard_detection_unit.v $RTL_PIPE/forwarding_unit.v \
            $RTL_CPU/pipelined_datapath.v $RTL_CPU/cpu_top.v \
            $ROOT/tb/cpu/pipelined_cpu_tb.v ;;
    cache_controller)
        compile_and_run $RTL_CACHE/cache_controller.v $ROOT/tb/cache/cache_controller_tb.v ;;
    cache_system)
        compile_and_run \
            $RTL_CACHE/cache_controller.v $RTL_MEM/main_memory.v \
            $RTL_CACHE/cache_system.v $ROOT/tb/cache/cache_system_tb.v ;;
    cdc_fifo|fifo)
        compile_and_run $RTL_FIFO/cdc_fifo.v $ROOT/tb/fifo/cdc_fifo_tb.v ;;
    *)
        echo "Unknown module: $MODULE"
        echo "Available: alu, register_file, immediate_generator, control_unit,"
        echo "           data_memory, instruction_memory, if_id, id_ex, ex_mem, mem_wb,"
        echo "           hazard_detection_unit, forwarding_unit, pipelined_cpu,"
        echo "           cache_controller, cache_system, cdc_fifo"
        exit 1 ;;
esac
