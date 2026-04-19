#!/usr/bin/env bash
# UVM simulation with AMD/Xilinx Vivado XSIM (xvlog → xelab → xsim). No Python / no cocotb.
#
# Prerequisite: load Vivado environment so xvlog, xelab, xsim are on PATH, e.g.
#   source /tools/Xilinx/Vivado/2023.1/settings64.sh
#   # or: source $XILINX_VIVADO/../settings64.sh
#   # or: export VIVADO_ROOT=/path/to/Vivado/2025.1/Vivado  (script sources $VIVADO_ROOT/settings64.sh if xvlog missing)
#
# DUT is Verilog from the same sv2v path as the Makefile ("make compile").
# UVM is the simulator-bundled library: pass -L uvm to xvlog/xelab (see UG900).
#
# Usage:
#   ./scripts/uvm_vivado_xsim.sh [gpu_matadd_test]
#   UVM_VIVADO_COMPILE_ONLY=1 ./scripts/uvm_vivado_xsim.sh   # compile/elab only, skip xsim
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TESTNAME="${1:-gpu_matadd_test}"
SNAP="${SNAP:-sim_gpu_tb}"

export PATH="${ROOT}/tools/bin:${PATH}"

if ! command -v xvlog >/dev/null 2>&1 && [[ -n "${VIVADO_ROOT:-}" && -f "${VIVADO_ROOT}/settings64.sh" ]]; then
  echo "[uvm_vivado_xsim] sourcing ${VIVADO_ROOT}/settings64.sh"
  # shellcheck disable=SC1090
  source "${VIVADO_ROOT}/settings64.sh"
fi

for c in xvlog xelab xsim; do
  if ! command -v "$c" >/dev/null 2>&1; then
    echo "error: '$c' not found. Source Vivado settings64.sh or set VIVADO_ROOT to .../Vivado/<ver>/Vivado" >&2
    exit 1
  fi
done

if ! command -v sv2v >/dev/null 2>&1; then
  echo "error: sv2v not found. Put sv2v in PATH or in ${ROOT}/tools/bin" >&2
  exit 1
fi

if ! command -v make >/dev/null 2>&1; then
  echo "error: make not found (needed for make compile → build/gpu.v)." >&2
  exit 1
fi

XV_I=(
  -i "$ROOT/src"
  -i "$ROOT/uvm/agents/memory_agent"
  -i "$ROOT/uvm/agents/host_ctrl_agent"
  -i "$ROOT/uvm/env"
  -i "$ROOT/uvm/scoreboard"
  -i "$ROOT/uvm/sequences"
  -i "$ROOT/uvm/tests"
  -i "$ROOT/uvm/top"
)

echo "[uvm_vivado_xsim] ROOT=$ROOT"
echo "[uvm_vivado_xsim] TESTNAME=$TESTNAME"

SIMDIR="$ROOT/sim_build/vivado_uvm"
rm -rf "$SIMDIR"
mkdir -p "$SIMDIR"
cd "$SIMDIR"

echo "[uvm_vivado_xsim] make compile (sv2v)..."
make -C "$ROOT" compile

echo "[uvm_vivado_xsim] xvlog DUT (Verilog)..."
xvlog "$ROOT/build/gpu.v"

echo "[uvm_vivado_xsim] xvlog testbench (SystemVerilog + UVM)..."
xvlog --sv -relax -L uvm "${XV_I[@]}" \
  "$ROOT/uvm/agents/memory_agent/memory_if.sv" \
  "$ROOT/uvm/agents/host_ctrl_agent/host_ctrl_if.sv" \
  "$ROOT/uvm/agents/host_ctrl_agent/host_ctrl_pkg.sv" \
  "$ROOT/uvm/agents/memory_agent/memory_pkg.sv" \
  "$ROOT/uvm/scoreboard/gpu_scoreboard_pkg.sv" \
  "$ROOT/uvm/env/gpu_env_pkg.sv" \
  "$ROOT/uvm/sequences/gpu_seq_pkg.sv" \
  "$ROOT/uvm/tests/gpu_test_pkg.sv" \
  "$ROOT/uvm/top/gpu_tb_top.sv"

echo "[uvm_vivado_xsim] xelab top gpu_tb_top..."
# xvlog uses library "work" by default (not xil_defaultlib).
xelab -relax -L uvm work.gpu_tb_top -s "$SNAP"

if [[ "${UVM_VIVADO_COMPILE_ONLY:-0}" == "1" ]]; then
  echo "[uvm_vivado_xsim] UVM_VIVADO_COMPILE_ONLY=1 — пропускаю xsim."
  echo "[uvm_vivado_xsim] done."
  exit 0
fi

echo "[uvm_vivado_xsim] xsim (UVM_TESTNAME=$TESTNAME)..."
# xsim does not accept bare +plusargs; use -testplusarg for UVM / $value$plusargs.
xsim "$SNAP" -runall -testplusarg "UVM_TESTNAME=$TESTNAME"

echo "[uvm_vivado_xsim] done."
