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
    `include "gpu_stress_test.sv"
endpackage
