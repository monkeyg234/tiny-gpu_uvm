class gpu_base_test extends uvm_test;
    `uvm_component_utils(gpu_base_test)

    gpu_env env;

    function new(string name = "gpu_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = gpu_env::type_id::create("env", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Clock agent VIF
        if (!uvm_config_db#(virtual clk_agent_if)::get(this, "", "clk_vif", env.clk_ag.driver.vif))
            `uvm_fatal("TEST", "Could not get clk_vif")

        // Reset agent VIF
        if (!uvm_config_db#(virtual rst_agent_if)::get(this, "", "rst_vif", env.rst_ag.driver.vif))
            `uvm_fatal("TEST", "Could not get rst_vif")
        env.rst_ag.monitor.vif = env.rst_ag.driver.vif;

        // Done agent VIF
        if (!uvm_config_db#(virtual done_agent_if)::get(this, "", "done_vif", env.done_ag.monitor.vif))
            `uvm_fatal("TEST", "Could not get done_vif")

        // Host control agent VIF
        if (!uvm_config_db#(virtual host_ctrl_if)::get(this, "", "h_vif", env.host_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get h_vif")
        env.host_agent.monitor.vif = env.host_agent.driver.vif;

        // Program memory agent VIF
        if (!uvm_config_db#(virtual memory_if#(8,16,1))::get(this, "", "p_vif", env.prog_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get p_vif")
        env.prog_mem_agent.monitor.vif = env.prog_mem_agent.driver.vif;

        // Data memory agent VIF
        if (!uvm_config_db#(virtual memory_if#(8,8,4))::get(this, "", "d_vif", env.data_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get d_vif")
        env.data_mem_agent.monitor.vif = env.data_mem_agent.driver.vif;
    endfunction

    // Convenience: start clock + reset sequence
    virtual task start_clk_and_reset();
        clk_item c_item;
        rst_item r_item;

        // Start clock (10ns period)
        c_item = clk_item::type_id::create("c_item");
        c_item.period_ns = 10;
        env.clk_ag.sequencer.execute_item(c_item);

        // Assert reset (20ns)
        r_item = rst_item::type_id::create("r_item");
        r_item.duration_ns = 20;
        env.rst_ag.sequencer.execute_item(r_item);
    endtask

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Base test started", UVM_LOW)
        start_clk_and_reset();
        #100ns;
        `uvm_info("TEST", "Base test finished", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
