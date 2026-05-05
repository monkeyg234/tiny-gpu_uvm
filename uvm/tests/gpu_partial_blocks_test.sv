// Partial blocks test: verifies thread_count 1..8.
// Ensures scheduler handles non-full blocks correctly.

class gpu_partial_blocks_test extends gpu_base_test;
    `uvm_component_utils(gpu_partial_blocks_test)

    function new(string name = "gpu_partial_blocks_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        for (int t = 1; t <= 8; t++) begin
            `uvm_info("TEST", $sformatf("=== Partial block test: %0d thread(s) ===", t), UVM_LOW)
            run_with_n_threads(t);

            begin
                host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
                h_clr.is_start_clear = 1;
                env.host_agent.sequencer.execute_item(h_clr);
            end
            if (env.cfg.en_coverage) env.coverage_col.reset();
            begin
                rst_item r = rst_item::type_id::create("r");
                r.duration_ns = 20;
                env.rst_ag.sequencer.execute_item(r);
            end
            #50ns;
        end

        `uvm_info("TEST", "All partial-block tests complete (1..8 threads)", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task run_with_n_threads(int n);
        logic [15:0] prog[6];
        prog[0] = 16'h51DE; // MUL R1, R13, R14
        prog[1] = 16'h321F; // ADD R2, R1, R15
        prog[2] = 16'h9310; // CONST R3, 16
        prog[3] = 16'h3323; // ADD R3, R2, R3
        prog[4] = 16'h803F; // STR R3, R15
        prog[5] = 16'hF000; // RET

        for (int i = 0; i < 6; i++) begin
            memory_item m = memory_item::type_id::create("m");
            m.op = memory_item::WRITE; m.addr = i; m.data = prog[i];
            env.prog_mem_agent.sequencer.execute_item(m);
        end

        for (int i = 0; i < 32; i++) begin
            memory_item d = memory_item::type_id::create("d");
            d.op = memory_item::WRITE; d.addr = i; d.data = 8'h00;
            env.data_mem_agent.sequencer.execute_item(d);
        end

        begin
            host_ctrl_item h = host_ctrl_item::type_id::create("h");
            h.is_write = 1; h.data = n;
            env.host_agent.sequencer.execute_item(h);
            h = host_ctrl_item::type_id::create("h2");
            h.is_write = 0;
            env.host_agent.sequencer.execute_item(h);
        end

        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", $sformatf("PASS: %0d thread(s)", n), UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", $sformatf("GPU HUNG with %0d thread(s)!", n))
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask
endclass
