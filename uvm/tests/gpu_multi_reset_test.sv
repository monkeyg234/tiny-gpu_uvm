// Multi-reset stress test: GPU reset at different moments, then correct operation.
// S1: 5 resets, no kernel. S2: start→reset→reset→launch. S3: 3 fast resets→launch. S4: reset after done.

class gpu_multi_reset_test extends gpu_base_test;
    `uvm_component_utils(gpu_multi_reset_test)

    function new(string name = "gpu_multi_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== S1: 5 consecutive resets (no kernel) ===", UVM_LOW)
        repeat (5) begin do_hw_reset(10); #20ns; end
        `uvm_info("TEST", "S1 PASS", UVM_LOW)

        `uvm_info("TEST", "=== S2: start -> reset -> reset -> launch ===", UVM_LOW)
        launch_kernel_only(4);
        #50ns; do_hw_reset(15);
        #30ns; do_hw_reset(15);
        #30ns;
        run_full_matadd_and_wait(4, "S2 clean launch");

        `uvm_info("TEST", "=== S3: 3 fast resets -> launch ===", UVM_LOW)
        repeat (3) begin do_hw_reset(10); #10ns; end
        run_full_matadd_and_wait(8, "S3 after rapid resets");

        `uvm_info("TEST", "=== S4: reset immediately after done ===", UVM_LOW)
        begin
            gpu_matadd_seq seq4a;
            seq4a = gpu_matadd_seq::type_id::create("seq4a");
            seq4a.num_threads = 4;
            seq4a.start(env.v_seqr, null, -1, 0);
        end
        env.done_ag.monitor.wait_for_done();
        #5ns;
        do_hw_reset(20);
        #20ns;
        if (env.cfg.en_coverage) env.coverage_col.reset();
        run_full_matadd_and_wait(4, "S4 after post-done reset");

        `uvm_info("TEST", "Multi-reset test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task do_hw_reset(int duration_ns);
        rst_item r = rst_item::type_id::create("r");
        r.duration_ns = duration_ns;
        env.rst_ag.sequencer.execute_item(r);
    endtask

    task launch_kernel_only(int threads);
        host_ctrl_item h;
        memory_item m0, m1;
        m0 = memory_item::type_id::create("m0");
        m0.op = memory_item::WRITE; m0.addr = 0; m0.data = 16'h912A; // CONST R0, 42
        env.prog_mem_agent.sequencer.execute_item(m0);
        m1 = memory_item::type_id::create("m1");
        m1.op = memory_item::WRITE; m1.addr = 1; m1.data = 16'hF000; // RET
        env.prog_mem_agent.sequencer.execute_item(m1);
        h = host_ctrl_item::type_id::create("h");
        h.is_write = 1; h.data = threads;
        env.host_agent.sequencer.execute_item(h);
        h = host_ctrl_item::type_id::create("h2");
        h.is_write = 0;
        env.host_agent.sequencer.execute_item(h);
    endtask

    task run_full_matadd_and_wait(int threads, string label);
        host_ctrl_item h_clr;
        gpu_matadd_seq seq;
        h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
        seq = gpu_matadd_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.start(env.v_seqr, null, -1, 0);
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", $sformatf("PASS: %s", label), UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", $sformatf("HUNG: %s", label))
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);
        h_clr = host_ctrl_item::type_id::create("h_clr2");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
        if (env.cfg.en_coverage) env.coverage_col.reset();
        do_hw_reset(20);
        #50ns;
    endtask
endclass
