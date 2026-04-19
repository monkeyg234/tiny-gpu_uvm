package gpu_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;
    import gpu_seq_pkg::*;

    `include "gpu_base_test.sv"
    `include "gpu_matadd_test.sv"
endpackage
