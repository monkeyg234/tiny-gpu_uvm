// Arbiter test sequence: creates high memory bus contention (8 threads x 4 STR).

class gpu_arbiter_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_arbiter_seq)

    function new(string name = "gpu_arbiter_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [15:0] prog[$] = '{
            16'h51DE, // MUL R1, R13, R14
            16'h321F, // ADD R2, R1, R15
            16'h9308, // CONST R3, 8
            16'h3423, // ADD R4, R2, R3
            16'h8042, // STR R4, R2 (write 1)
            16'h9310, // CONST R3, 16
            16'h3423, // ADD R4, R2, R3
            16'h8042, // STR R4, R2 (write 2)
            16'h9318, // CONST R3, 24
            16'h3423, // ADD R4, R2, R3
            16'h8042, // STR R4, R2 (write 3)
            16'h9320, // CONST R3, 32
            16'h3423, // ADD R4, R2, R3
            16'h8042, // STR R4, R2 (write 4)
            16'hF000  // RET
        };

        logic [7:0] zeros[$];
        for (int i = 0; i < 48; i++) zeros.push_back(8'h00);

        load_program(prog);
        load_data(0, zeros);
        launch_kernel(8);
        `uvm_info("ARBITER_SEQ", "8 threads, 32 total writes (max contention)", UVM_LOW)
    endtask
endclass
