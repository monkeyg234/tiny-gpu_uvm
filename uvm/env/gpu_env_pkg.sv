package gpu_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import clk_pkg::*;
    import rst_pkg::*;
    import done_pkg::*;
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_scoreboard_pkg::*;

    `include "gpu_env.sv"
endpackage
