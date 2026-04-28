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
        
        seq.host_seqr = env.host_agent.sequencer;
        seq.prog_seqr = env.prog_mem_agent.sequencer;
        seq.data_seqr = env.data_mem_agent.sequencer;
        
        `uvm_info("TEST", "Starting MatAdd sequence", UVM_LOW)
        seq.start(null);
        
        // Wait for GPU done via done_agent monitor (clean UVM approach)
        `uvm_info("TEST", "Waiting for GPU done signal", UVM_LOW)
        env.done_ag.monitor.wait_for_done();
        
        #100ns;
        `uvm_info("TEST", "MatAdd test finished", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
endclass
