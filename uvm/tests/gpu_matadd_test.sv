class gpu_matadd_test extends gpu_base_test;
    `uvm_component_utils(gpu_matadd_test)

    function new(string name = "gpu_matadd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_matadd_seq seq = gpu_matadd_seq::type_id::create("seq");
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "Starting MatAdd (8 threads)", UVM_LOW)
        seq.num_threads = 8;
        seq.start(env.v_seqr, null, -1, 0);

        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST", "MatAdd timeout!")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        phase.drop_objection(this);
    endtask
endclass
