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

            `uvm_info("TEST", $sformatf("=== ITERATION %0d: Starting sequence with %0d threads ===", iteration, seq.num_threads), UVM_LOW)
            seq.start(env.v_seqr, null, -1, 0);

            `uvm_info("TEST", "Waiting for GPU done signal...", UVM_LOW)
            fork
                begin
                    env.done_ag.monitor.wait_for_done();
                end
                begin
                    #(env.cfg.watchdog_timeout_ns * 1ns);
                    `uvm_error("TEST_TIMEOUT", $sformatf(
                        "DUT hang detected in iteration %0d! The GPU locked up and never asserted the done signal (known bugs in RTL: next_pc update on inactive threads, and static any_lsu_waiting).",
                        iteration))
                end
            join_any
            disable fork;

            // Сбрасываем start через чистую UVM-транзакцию
            begin
                host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
                h_clr.is_start_clear = 1;
                env.host_agent.sequencer.execute_item(h_clr);
            end

            // Reset the scoreboard and coverage state for the next iteration
            if (env.cfg.en_scoreboard)
                env.scoreboard.reset();
            if (env.cfg.en_coverage)
                env.coverage_col.reset();

            // Сброс на лету (On-the-fly Reset) для следующей итерации
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
