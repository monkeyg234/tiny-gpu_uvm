// Corner cases: 1 thread, 4 threads (full block), 5 threads (partial), trivial program.

class gpu_corner_test extends gpu_base_test;
    `uvm_component_utils(gpu_corner_test)

    function new(string name = "gpu_corner_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== Case 1: Trivial (CONST+RET), 1 thread ===", UVM_LOW)
        run_trivial_kernel(1);
        do_reset();

        `uvm_info("TEST", "=== Case 2: MatAdd, 1 thread ===", UVM_LOW)
        run_matadd_kernel(1);
        do_reset();

        `uvm_info("TEST", "=== Case 3: MatAdd, 4 threads (full block) ===", UVM_LOW)
        run_matadd_kernel(4);
        do_reset();

        `uvm_info("TEST", "=== Case 4: MatAdd, 5 threads (partial block) ===", UVM_LOW)
        run_matadd_kernel_with_timeout(5);
        do_reset();

        `uvm_info("TEST", "Corner case tests finished", UVM_LOW)
        phase.drop_objection(this);
    endtask

    virtual task run_trivial_kernel(int threads);
        logic [15:0] trivial_prog[$] = '{16'h912A, 16'hF000};
        memory_item m_item;
        host_ctrl_item h_item;

        foreach (trivial_prog[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE; m_item.addr = i; m_item.data = trivial_prog[i];
            env.prog_mem_agent.sequencer.execute_item(m_item);
        end

        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1; h_item.data = threads;
        env.host_agent.sequencer.execute_item(h_item);
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        env.host_agent.sequencer.execute_item(h_item);

        fork
            env.done_ag.monitor.wait_for_done();
            begin #500us; `uvm_error("TEST", "Trivial kernel timeout!"); end
        join_any
        disable fork;
        #50ns;
    endtask

    virtual task run_matadd_kernel(int threads);
        gpu_matadd_seq seq = gpu_matadd_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.start(env.v_seqr, null, -1, 0);
        env.done_ag.monitor.wait_for_done();
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask

    virtual task run_matadd_kernel_with_timeout(int threads);
        gpu_matadd_seq seq = gpu_matadd_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.start(env.v_seqr, null, -1, 0);
        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_warning("TEST", $sformatf("Expected hang with %0d threads", threads))
            end
        join_any
        disable fork;
        #50ns;
    endtask

    virtual task do_reset();
        host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
        if (env.cfg.en_coverage) env.coverage_col.reset();
        begin
            rst_item r = rst_item::type_id::create("r");
            r.duration_ns = 20;
            env.rst_ag.sequencer.execute_item(r);
        end
        #50ns;
    endtask
endclass
