class gpu_stress_test extends gpu_base_test;
    `uvm_component_utils(gpu_stress_test)

    function new(string name = "gpu_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_stress_seq seq;
        
        phase.raise_objection(this);

        // Start clock & reset via agents
        start_clk_and_reset();
        
        // Циклическое повторение: запуск 5 итераций со случайным числом потоков
        for (int iteration = 0; iteration < 5; iteration++) begin
            seq = gpu_stress_seq::type_id::create("seq");
            
            if (!seq.randomize()) begin
                `uvm_fatal("TEST", "Failed to randomize gpu_stress_seq")
            end
            
            seq.host_seqr = env.host_agent.sequencer;
            seq.prog_seqr = env.prog_mem_agent.sequencer;
            seq.data_seqr = env.data_mem_agent.sequencer;
            
            `uvm_info("TEST", $sformatf("=== ITERATION %0d: Starting sequence with %0d threads ===", iteration, seq.num_threads), UVM_LOW)
            seq.start(null);
            
            `uvm_info("TEST", "Waiting for GPU done signal...", UVM_LOW)
            fork
                begin
                    env.done_ag.monitor.wait_for_done();
                end
                begin
                    #2ms; // Timeout
                    `uvm_error("TEST_TIMEOUT", $sformatf("DUT hang detected in iteration %0d! The GPU locked up and never asserted the done signal (known bugs in RTL: next_pc update on inactive threads, and static any_lsu_waiting).", iteration))
                end
            join_any
            disable fork;
            
            // Clear the start signal so the DUT doesn't immediately assert 'done' after reset
            begin
                virtual host_ctrl_if h_vif;
                if(uvm_config_db#(virtual host_ctrl_if)::get(this, "", "h_vif", h_vif)) begin
                    h_vif.start <= 1'b0;
                end
            end
            
            // Reset the scoreboard state for the next iteration to prevent mismatches
            env.scoreboard.reset();
            
            // Сброс на лету (On-the-fly Reset) для следующей итерации, 
            // чтобы проверить что GPU корректно очищается
            `uvm_info("TEST", "Sending ON-THE-FLY RESET", UVM_LOW)
            begin
                rst_item r_item = rst_item::type_id::create("r_item");
                r_item.duration_ns = 20;
                env.rst_ag.sequencer.execute_item(r_item);
            end
            #50ns;
        end
        
        `uvm_info("TEST", "Stress test finished successfully!", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
endclass
