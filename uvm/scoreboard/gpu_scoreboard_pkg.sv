package gpu_scoreboard_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import done_pkg::*;

    // Reference model modules (order matters — dependencies first)
    `include "ref_model/alu_ref.sv"
    `include "ref_model/decoder_ref.sv"
    `include "ref_model/regfile_ref.sv"
    `include "ref_model/pc_ref.sv"
    `include "ref_model/core_ref.sv"
    `include "ref_model/dispatcher_ref.sv"
    `include "ref_model/gpu_ref.sv"

    // Scoreboard
    `include "gpu_scoreboard.sv"
endpackage
