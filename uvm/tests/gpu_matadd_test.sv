class gpu_matadd_test extends gpu_base_test;
    `uvm_component_utils(gpu_matadd_test)

    function new(string name = "gpu_matadd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_matadd_seq seq;
        seq = gpu_matadd_seq::type_id::create("seq");

        phase.raise_objection(this);

        // Start clock & reset via agents
        start_clk_and_reset();

        `uvm_info("TEST", "Starting MatAdd sequence", UVM_LOW)
        seq.num_threads = 8;
        seq.set_starting_phase(phase);
        seq.start(env.v_seqr, null, -1, 0); // 0 = don't call pre/post_body

        // Wait for GPU done via done_agent monitor
        `uvm_info("TEST", "Waiting for GPU done signal", UVM_LOW)
        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST", "MatAdd timed out!")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        `uvm_info("TEST", "MatAdd test finished", UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass
