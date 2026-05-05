// Reset during memory write (LSU WAITING state).
// S: Launch 32-STR kernel, reset at 400ns, then verify recovery with MatAdd.

class gpu_reset_during_str_test extends gpu_base_test;
    `uvm_component_utils(gpu_reset_during_str_test)

    function new(string name = "gpu_reset_during_str_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== Launching 32-STR kernel (arbiter_seq) ===", UVM_LOW)
        begin
            gpu_arbiter_seq seq;
            seq = gpu_arbiter_seq::type_id::create("seq");
            seq.start(env.v_seqr, null, -1, 0);
        end

        #400ns;
        `uvm_info("TEST", "=== Injecting RESET during STR (LSU WAITING state) ===", UVM_LOW)
        begin
            rst_item r = rst_item::type_id::create("r");
            r.duration_ns = 30;
            env.rst_ag.sequencer.execute_item(r);
        end
        #100ns;

        if (env.cfg.en_coverage) env.coverage_col.reset();
        `uvm_info("TEST", "=== Post-STR-reset: launching clean MatAdd ===", UVM_LOW)
        begin
            gpu_matadd_seq seq2;
            seq2 = gpu_matadd_seq::type_id::create("seq2");
            seq2.num_threads = 8;
            seq2.start(env.v_seqr, null, -1, 0);
        end

        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "PASS: GPU recovered after reset-during-STR", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "GPU hung after reset during STR!")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        begin
            host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
            h_clr.is_start_clear = 1;
            env.host_agent.sequencer.execute_item(h_clr);
        end

        `uvm_info("TEST", "Reset-during-STR test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
