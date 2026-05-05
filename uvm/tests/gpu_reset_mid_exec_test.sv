// Reset mid-execution test.
// S1: MatAdd 8t, reset after 200ns, then clean relaunch.
// S2: Reset 1 cycle after start (early abort), then clean relaunch.

class gpu_reset_mid_exec_test extends gpu_base_test;
    `uvm_component_utils(gpu_reset_mid_exec_test)

    function new(string name = "gpu_reset_mid_exec_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== SCENARIO 1: Reset mid-execution (after ~200ns) ===", UVM_LOW)
        begin
            gpu_matadd_seq seq;
            seq = gpu_matadd_seq::type_id::create("seq");
            seq.num_threads = 8;
            seq.start(env.v_seqr, null, -1, 0);
        end
        #200ns;
        `uvm_info("TEST", "Injecting RESET mid-execution!", UVM_LOW)
        begin
            rst_item r_item = rst_item::type_id::create("r_item");
            r_item.duration_ns = 30;
            env.rst_ag.sequencer.execute_item(r_item);
        end
        #50ns;
        if (env.cfg.en_coverage) env.coverage_col.reset();

        `uvm_info("TEST", "Post-reset: launching clean kernel to verify GPU recovered", UVM_LOW)
        begin
            gpu_matadd_seq seq2;
            seq2 = gpu_matadd_seq::type_id::create("seq2");
            seq2.num_threads = 8;
            seq2.start(env.v_seqr, null, -1, 0);
        end
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "SCENARIO 1 PASS: GPU recovered after mid-exec reset", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "GPU did not recover after mid-execution reset!")
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);

        do_host_clear();
        if (env.cfg.en_coverage) env.coverage_col.reset();
        begin
            rst_item r = rst_item::type_id::create("r");
            r.duration_ns = 20;
            env.rst_ag.sequencer.execute_item(r);
        end
        #50ns;

        `uvm_info("TEST", "=== SCENARIO 2: Reset 1 cycle after start (early abort) ===", UVM_LOW)
        begin
            gpu_dual_done_seq seq3;
            seq3 = gpu_dual_done_seq::type_id::create("seq3");
            seq3.start(env.v_seqr, null, -1, 0);
        end
        #10ns;
        `uvm_info("TEST", "Injecting IMMEDIATE RESET (1 cycle after start)!", UVM_LOW)
        begin
            rst_item r2 = rst_item::type_id::create("r2");
            r2.duration_ns = 20;
            env.rst_ag.sequencer.execute_item(r2);
        end
        #50ns;
        if (env.cfg.en_coverage) env.coverage_col.reset();

        `uvm_info("TEST", "Post early-reset: launching clean 4-thread kernel", UVM_LOW)
        begin
            gpu_matadd_seq seq4;
            seq4 = gpu_matadd_seq::type_id::create("seq4");
            seq4.num_threads = 4;
            seq4.start(env.v_seqr, null, -1, 0);
        end
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "SCENARIO 2 PASS: GPU recovered after immediate reset", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "GPU stuck after early-abort reset!")
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);

        do_host_clear();
        `uvm_info("TEST", "Reset mid-exec test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task do_host_clear();
        host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
    endtask
endclass
