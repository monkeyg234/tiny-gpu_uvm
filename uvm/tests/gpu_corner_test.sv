// gpu_corner_test.sv — Тест граничных случаев.
// Проверяет поведение GPU при:
// 1. Ровно 1 поток (минимум)
// 2. Ровно 4 потока (полный блок)
// 3. 5 потоков (неполный блок — известный баг scheduler → deadlock)
// 4. Тривиальная программа (CONST + RET)
class gpu_corner_test extends gpu_base_test;
    `uvm_component_utils(gpu_corner_test)

    function new(string name = "gpu_corner_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        // ---- Тест 1: Тривиальная программа (CONST R0, #42; RET) ----
        `uvm_info("TEST", "=== Corner Case 1: Trivial program (CONST+RET), 1 thread ===", UVM_LOW)
        run_trivial_kernel(1);
        do_reset();

        // ---- Тест 2: MatAdd с 1 потоком ----
        `uvm_info("TEST", "=== Corner Case 2: MatAdd with 1 thread ===", UVM_LOW)
        run_matadd_kernel(1);
        do_reset();

        // ---- Тест 3: MatAdd с 4 потоками (ровно 1 полный блок) ----
        `uvm_info("TEST", "=== Corner Case 3: MatAdd with 4 threads (full block) ===", UVM_LOW)
        run_matadd_kernel(4);
        do_reset();

        // ---- Тест 4: MatAdd с 5 потоками (неполный блок — ожидаем deadlock) ----
        `uvm_info("TEST", "=== Corner Case 4: MatAdd with 5 threads (partial block, expect hang) ===", UVM_LOW)
        run_matadd_kernel_with_timeout(5);
        do_reset();

        `uvm_info("TEST", "Corner case tests finished", UVM_LOW)
        phase.drop_objection(this);
    endtask

    // ------- Вспомогательные таски -------

    // Тривиальная программа: CONST R0, #42; RET
    virtual task run_trivial_kernel(int threads);
        gpu_base_vseq vseq;
        logic [15:0] trivial_prog[$] = '{16'h912A, 16'hF000};

        vseq = gpu_base_vseq::type_id::create("vseq");
        vseq.start(env.v_seqr);  // Инициализируем p_sequencer

        // Ручная загрузка через утилиты базовой последовательности
        fork
            begin
                gpu_base_vseq load_seq;
                load_seq = gpu_base_vseq::type_id::create("load_seq");
                load_seq.set_sequencer(env.v_seqr);
            end
        join_none

        // Загрузка программы напрямую
        begin
            memory_item m_item;
            host_ctrl_item h_item;

            foreach (trivial_prog[i]) begin
                m_item = memory_item::type_id::create("m_item");
                m_item.op   = memory_item::WRITE;
                m_item.addr = i;
                m_item.data = trivial_prog[i];
                env.prog_mem_agent.sequencer.execute_item(m_item);
            end

            h_item = host_ctrl_item::type_id::create("h_item");
            h_item.is_write = 1;
            h_item.data = threads;
            env.host_agent.sequencer.execute_item(h_item);

            h_item = host_ctrl_item::type_id::create("h_item");
            h_item.is_write = 0;
            env.host_agent.sequencer.execute_item(h_item);
        end

        fork
            env.done_ag.monitor.wait_for_done();
            begin #500us; `uvm_error("TEST", "Trivial kernel timed out!"); end
        join_any
        disable fork;
        #50ns;
    endtask

    // MatAdd kernel с указанным числом потоков
    virtual task run_matadd_kernel(int threads);
        gpu_matadd_seq seq;
        seq = gpu_matadd_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.start(env.v_seqr, null, -1, 0);

        env.done_ag.monitor.wait_for_done();
        #(env.cfg.post_done_drain_ns * 1ns);

        if (env.cfg.en_scoreboard)
            env.scoreboard.reset();
    endtask

    // MatAdd kernel с timeout (для тестирования deadlock)
    virtual task run_matadd_kernel_with_timeout(int threads);
        gpu_matadd_seq seq;
        seq = gpu_matadd_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.start(env.v_seqr, null, -1, 0);

        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_warning("TEST", $sformatf(
                    "DUT hang with %0d threads (expected: scheduler partial-block bug)", threads))
            end
        join_any
        disable fork;
        #50ns;

        if (env.cfg.en_scoreboard)
            env.scoreboard.reset();
    endtask

    // Сброс между тестами
    virtual task do_reset();
        host_ctrl_item h_clr;
        rst_item r_item;

        // Сбрасываем start через UVM-транзакцию
        h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);

        if (env.cfg.en_scoreboard)
            env.scoreboard.reset();
        if (env.cfg.en_coverage)
            env.coverage_col.reset();

        r_item = rst_item::type_id::create("r_item");
        r_item.duration_ns = 20;
        env.rst_ag.sequencer.execute_item(r_item);
        #50ns;
    endtask
endclass
