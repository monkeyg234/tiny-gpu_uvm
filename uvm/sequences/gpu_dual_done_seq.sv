// Dual-done sequence: launches 8 threads (2 full blocks) to trigger simultaneous completion.

class gpu_dual_done_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_dual_done_seq)

    function new(string name = "gpu_dual_done_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [15:0] prog[$] = '{
            16'h51DE, // MUL  R1, R13, R14
            16'h321F, // ADD  R2, R1,  R15
            16'h9320, // CONST R3, 0x20
            16'h3323, // ADD  R3, R2,  R3
            16'h803F, // STR  R3, R15
            16'hF000  // RET
        };

        logic [7:0] zeros[$];
        for (int i = 0; i < 48; i++) zeros.push_back(8'h00);

        load_program(prog);
        load_data(0, zeros);
        launch_kernel(8);
        `uvm_info("DUAL_DONE_SEQ", "8 threads (2 blocks) — simultaneous completion test", UVM_LOW)
    endtask
endclass
