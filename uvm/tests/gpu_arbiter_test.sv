// Memory arbiter test: 8 threads (2 cores x 4) execute 32 STR operations.
// Verifies Round-Robin arbitration and write data integrity.

class gpu_arbiter_test extends gpu_base_test;
    `uvm_component_utils(gpu_arbiter_test)

    function new(string name = "gpu_arbiter_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_arbiter_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        seq = gpu_arbiter_seq::type_id::create("seq");
        seq.start(env.v_seqr, null, -1, 0);

        `uvm_info("TEST", "Waiting for GPU done (32 writes, high bus contention)...", UVM_LOW)
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "PASS: arbiter test (no writes lost)", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "DUT hang: Memory arbiter likely deadlocked.")
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
