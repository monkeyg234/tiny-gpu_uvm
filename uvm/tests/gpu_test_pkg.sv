package gpu_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import clk_pkg::*;
    import rst_pkg::*;
    import done_pkg::*;
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;
    import gpu_seq_pkg::*;

    `include "gpu_base_test.sv"
    `include "gpu_matadd_test.sv"
    `include "gpu_matmul_test.sv"
    `include "gpu_corner_test.sv"
    `include "gpu_stress_test.sv"
    `include "gpu_dual_done_test.sv"
    `include "gpu_arbiter_test.sv"
    `include "gpu_reset_mid_exec_test.sv"
    `include "gpu_reset_during_str_test.sv"
    `include "gpu_back_to_back_test.sv"
    `include "gpu_partial_blocks_test.sv"
    `include "gpu_multi_reset_test.sv"
endpackage
