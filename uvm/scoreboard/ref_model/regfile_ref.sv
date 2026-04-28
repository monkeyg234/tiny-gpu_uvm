class regfile_ref;

    logic [7:0] regs [16];
    int thread_id;
    int threads_per_block;

    function new(int tid, int tpb);
        this.thread_id        = tid;
        this.threads_per_block = tpb;
    endfunction

    function void reset(logic [7:0] block_id);
        for (int i = 0; i < 13; i++)
            regs[i] = 8'h0;
        regs[13] = block_id;
        regs[14] = threads_per_block[7:0];
        regs[15] = thread_id[7:0];
    endfunction

    function logic [7:0] read(logic [3:0] addr);
        return regs[addr];
    endfunction

    function void write(logic [3:0] addr, logic [7:0] data);
        if (addr < 13)
            regs[addr] = data;
    endfunction

endclass
