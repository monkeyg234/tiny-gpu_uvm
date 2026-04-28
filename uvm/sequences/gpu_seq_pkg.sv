package gpu_seq_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import host_ctrl_pkg::*;
    import memory_pkg::*;

    `include "gpu_matadd_seq.sv"
    `include "gpu_stress_seq.sv"
endpackage
