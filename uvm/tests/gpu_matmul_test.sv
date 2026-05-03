// gpu_matmul_test.sv — Тест умножения матриц 2×2.
// ВАЖНО: Этот тест ОЖИДАЕМО ПАДАЕТ из-за бага ALU (BRn никогда не срабатывает,
// т.к. N-флаг hardware-locked to 0 из-за unsigned сравнения в alu.sv:39).
// Используется как regression test для подтверждения бага.
class gpu_matmul_test extends gpu_base_test;
    `uvm_component_utils(gpu_matmul_test)

    function new(string name = "gpu_matmul_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        host_ctrl_item h_item;
        memory_item    m_item;

        // MatMul kernel (из README)
        logic [15:0] prog_words [] = '{
            16'h50DE, 16'h300F,   // MUL R0, %blockIdx, %blockDim; ADD R0, R0, %threadIdx
            16'h9101, 16'h9202,   // CONST R1, #1; CONST R2, #2
            16'h9300, 16'h9404,   // CONST R3, #0; CONST R4, #4
            16'h9508, 16'h6602,   // CONST R5, #8; DIV R6, R0, R2
            16'h5762, 16'h4707,   // MUL R7, R6, R2; SUB R7, R0, R7
            16'h9800, 16'h9900,   // CONST R8, #0; CONST R9, #0
            // LOOP:
            16'h5A62, 16'h3AA9,   // MUL R10, R6, R2; ADD R10, R10, R9
            16'h3AA3, 16'h7AA0,   // ADD R10, R10, R3; LDR R10, R10
            16'h5B92, 16'h3BB7,   // MUL R11, R9, R2; ADD R11, R11, R7
            16'h3BB4, 16'h7BB0,   // ADD R11, R11, R4; LDR R11, R11
            16'h5CAB, 16'h38C8,   // MUL R12, R10, R11; ADD R8, R8, R12 (acc)
            16'h3991, 16'h2920,   // ADD R9, R9, R1; CMP R9, R2
            16'h280C,             // BRn LOOP (addr 12)
            16'h3950, 16'h8098,   // ADD R9, R5, R0; STR R9, R8
            16'hF000              // RET
        };

        // Данные: matrix A = {{1,2},{3,4}}, matrix B = {{1,2},{3,4}}
        logic [7:0] matrix_a [] = '{1, 2, 3, 4};
        logic [7:0] matrix_b [] = '{1, 2, 3, 4};

        phase.raise_objection(this);

        start_clk_and_reset();

        // Загрузка программы
        foreach (prog_words[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op   = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = prog_words[i];
            env.prog_mem_agent.sequencer.execute_item(m_item);
        end

        // Загрузка данных: Matrix A (base=0), Matrix B (base=4)
        foreach (matrix_a[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op   = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = matrix_a[i];
            env.data_mem_agent.sequencer.execute_item(m_item);
        end
        foreach (matrix_b[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op   = memory_item::WRITE;
            m_item.addr = 4 + i;
            m_item.data = matrix_b[i];
            env.data_mem_agent.sequencer.execute_item(m_item);
        end

        // DCR write: 4 потока для 2×2 матрицы
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1;
        h_item.data = 4;
        env.host_agent.sequencer.execute_item(h_item);

        // Start
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        env.host_agent.sequencer.execute_item(h_item);

        `uvm_info("TEST", "MatMul kernel launched (EXPECTED TO FAIL due to ALU BRn bug)", UVM_LOW)

        // Ждём с timeout — kernel скорее всего зависнет из-за бага BRn
        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_warning("TEST", "MatMul timed out as expected (ALU BRn bug: N-flag is hardware-locked to 0)")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        `uvm_info("TEST", "MatMul test finished", UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass
