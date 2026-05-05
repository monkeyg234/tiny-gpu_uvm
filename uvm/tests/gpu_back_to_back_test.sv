// Back-to-back kernels without hardware reset between them.
// Verifies done doesn't stick and dispatch reinitializes cleanly on new start.

class gpu_back_to_back_test extends gpu_base_test;
    `uvm_component_utils(gpu_back_to_back_test)

    int kernel_num;

    function new(string name = "gpu_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
        kernel_num = 0;
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== KERNEL 1: MatAdd 8 threads ===", UVM_LOW)
        begin
            gpu_matadd_seq seq;
            seq = gpu_matadd_seq::type_id::create("seq");
            seq.num_threads = 8;
            seq.start(env.v_seqr, null, -1, 0);
        end
        wait_done_or_timeout("Kernel 1 (MatAdd 8t)");
        clear_start_no_reset();

        `uvm_info("TEST", "=== KERNEL 2: MatAdd 4 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        begin
            gpu_matadd_seq seq;
            seq = gpu_matadd_seq::type_id::create("seq");
            seq.num_threads = 4;
            seq.start(env.v_seqr, null, -1, 0);
        end
        wait_done_or_timeout("Kernel 2 (MatAdd 4t, no reset)");
        clear_start_no_reset();

        `uvm_info("TEST", "=== KERNEL 3: MatAdd 8 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        begin
            gpu_matadd_seq seq;
            seq = gpu_matadd_seq::type_id::create("seq");
            seq.num_threads = 8;
            seq.start(env.v_seqr, null, -1, 0);
        end
        wait_done_or_timeout("Kernel 3 (MatAdd 8t, no reset)");
        clear_start_no_reset();

        `uvm_info("TEST", "Back-to-back test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task wait_done_or_timeout(string label);
        fork
            begin
                real t_start, t_end;
                t_start = $realtime;
                env.done_ag.monitor.wait_for_done();
                t_end = $realtime;
                // done < 50ns after launch is suspicious — may be sticky from previous kernel
                if ((t_end - t_start) < 50)
                    `uvm_error("TEST", $sformatf("%s: done too fast (%.0fns)! Sticky done?", label, t_end - t_start))
                else
                    `uvm_info("TEST", $sformatf("%s PASS: done after %.0fns", label, t_end - t_start), UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", $sformatf("%s: GPU hung!", label))
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask

    task clear_start_no_reset();
        host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
        #20ns;
    endtask
endclass
