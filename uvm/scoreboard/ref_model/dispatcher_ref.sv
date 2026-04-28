class dispatcher_ref;

    int num_cores;
    int threads_per_block;

    function new(int nc = 2, int tpb = 4);
        num_cores        = nc;
        threads_per_block = tpb;
    endfunction

    function int get_total_blocks(int thread_count);
        return (thread_count + threads_per_block - 1) / threads_per_block;
    endfunction

    function int get_block_thread_count(int block_id, int thread_count);
        int total_blocks = get_total_blocks(thread_count);
        if (block_id == total_blocks - 1)
            return thread_count - (block_id * threads_per_block);
        else
            return threads_per_block;
    endfunction

endclass
