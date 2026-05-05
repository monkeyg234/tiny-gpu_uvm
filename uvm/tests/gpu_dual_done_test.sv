// Dual-core simultaneous done test: 8 threads (2 blocks of 4), both cores finish at same cycle.
// Verifies blocks_done counter handles simultaneous core_done correctly.

class gpu_dual_done_test extends gpu_base_test;
    `uvm_component_utils(gpu_dual_done_test)

    function new(string name = "gpu_dual_done_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_dual_done_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        seq = gpu_dual_done_seq::type_id::create("seq");
        seq.start(env.v_seqr, null, -1, 0);

        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "PASS: dual-block done", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "DUT hang: blocks_done may have lost simultaneous core_done signal.")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        begin
            host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
            h_clr.is_start_clear = 1;
            env.host_agent.sequencer.execute_item(h_clr);
        end

        phase.drop_objection(this);
    endtask
endclass
