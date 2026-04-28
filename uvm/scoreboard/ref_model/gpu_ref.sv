class gpu_ref_model;

    localparam int NUM_CORES        = 2;
    localparam int THREADS_PER_BLOCK = 4;

    dispatcher_ref dispatcher;
    core_ref       cores[NUM_CORES];

    logic [15:0] prog_mem [256];
    logic [7:0]  data_mem [256];

    logic [7:0]  expected_data_mem [256];
    core_ref::mem_write_t expected_writes[$];

    int thread_count;
    bit executed;

    function new();
        dispatcher = new(NUM_CORES, THREADS_PER_BLOCK);
        for (int i = 0; i < NUM_CORES; i++)
            cores[i] = new(THREADS_PER_BLOCK);
        reset();
    endfunction

    function void reset();
        for (int i = 0; i < 256; i++) begin
            prog_mem[i] = 16'h0;
            data_mem[i] = 8'h0;
            expected_data_mem[i] = 8'h0;
        end
        expected_writes.delete();
        thread_count = 0;
        executed = 0;
    endfunction

    function void load_prog(logic [7:0] addr, logic [15:0] data);
        prog_mem[addr] = data;
    endfunction

    function void load_data(logic [7:0] addr, logic [7:0] data);
        data_mem[addr] = data;
    endfunction

    function void set_thread_count(int tc);
        thread_count = tc;
    endfunction

    function void execute();
        int total_blocks;
        int blocks_dispatched;

        for (int i = 0; i < 256; i++)
            expected_data_mem[i] = data_mem[i];

        total_blocks = dispatcher.get_total_blocks(thread_count);
        blocks_dispatched = 0;
        expected_writes.delete();

        while (blocks_dispatched < total_blocks) begin
            for (int c = 0; c < NUM_CORES && blocks_dispatched < total_blocks; c++) begin
                int block_tc;
                block_tc = dispatcher.get_block_thread_count(blocks_dispatched, thread_count);

                cores[c].execute_block(
                    blocks_dispatched[7:0],
                    block_tc,
                    prog_mem,
                    expected_data_mem
                );

                foreach (cores[c].mem_writes[w])
                    expected_writes.push_back(cores[c].mem_writes[w]);

                blocks_dispatched++;
            end
        end

        executed = 1;
    endfunction

    function logic [7:0] get_expected(logic [7:0] addr);
        return expected_data_mem[addr];
    endfunction

    function bit check_write(logic [7:0] addr, logic [7:0] actual_data);
        if (executed && actual_data === expected_data_mem[addr])
            return 1;
        else
            return 0;
    endfunction

endclass
