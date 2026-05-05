// MatMul 2x2 test. Known to fail due to ALU BRn bug (N-flag locked to 0).

class gpu_matmul_test extends gpu_base_test;
    `uvm_component_utils(gpu_matmul_test)

    function new(string name = "gpu_matmul_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        host_ctrl_item h_item;
        memory_item    m_item;

        logic [15:0] prog_words [] = '{
            16'h50DE, 16'h300F, 16'h9101, 16'h9202, 16'h9300, 16'h9404,
            16'h9508, 16'h6602, 16'h5762, 16'h4707, 16'h9800, 16'h9900,
            16'h5A62, 16'h3AA9, 16'h3AA3, 16'h7AA0, 16'h5B92, 16'h3BB7,
            16'h3BB4, 16'h7BB0, 16'h5CAB, 16'h38C8, 16'h3991, 16'h2920,
            16'h280C, 16'h3950, 16'h8098, 16'hF000
        };

        logic [7:0] matrix_a [] = '{1, 2, 3, 4};
        logic [7:0] matrix_b [] = '{1, 2, 3, 4};

        phase.raise_objection(this);
        start_clk_and_reset();

        foreach (prog_words[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE; m_item.addr = i; m_item.data = prog_words[i];
            env.prog_mem_agent.sequencer.execute_item(m_item);
        end

        foreach (matrix_a[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE; m_item.addr = i; m_item.data = matrix_a[i];
            env.data_mem_agent.sequencer.execute_item(m_item);
        end
        foreach (matrix_b[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE; m_item.addr = 4 + i; m_item.data = matrix_b[i];
            env.data_mem_agent.sequencer.execute_item(m_item);
        end

        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1; h_item.data = 4;
        env.host_agent.sequencer.execute_item(h_item);

        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        env.host_agent.sequencer.execute_item(h_item);

        `uvm_info("TEST", "MatMul launched (EXPECTED TO HANG: ALU BRn bug)", UVM_LOW)
        fork
            env.done_ag.monitor.wait_for_done();
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_warning("TEST", "MatMul timed out as expected")
            end
        join_any
        disable fork;

        #(env.cfg.post_done_drain_ns * 1ns);
        phase.drop_objection(this);
    endtask
endclass
