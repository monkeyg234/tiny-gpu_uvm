class gpu_stress_test extends gpu_base_test;
    `uvm_component_utils(gpu_stress_test)

    function new(string name = "gpu_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_stress_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        for (int iteration = 0; iteration < 5; iteration++) begin
            seq = gpu_stress_seq::type_id::create("seq");
            if (!seq.randomize()) `uvm_fatal("TEST", "Randomization failed")

            `uvm_info("TEST", $sformatf("=== ITERATION %0d: %0d threads ===", iteration, seq.num_threads), UVM_LOW)
            seq.start(env.v_seqr, null, -1, 0);

            fork
                begin
                    env.done_ag.monitor.wait_for_done();
                end
                begin
                    #(env.cfg.watchdog_timeout_ns * 1ns);
                    `uvm_error("TEST_TIMEOUT", $sformatf("DUT hang in iteration %0d", iteration))
                end
            join_any
            disable fork;

            begin
                host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
                h_clr.is_start_clear = 1;
                env.host_agent.sequencer.execute_item(h_clr);
            end

            if (env.cfg.en_coverage) env.coverage_col.reset();

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
