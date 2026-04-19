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
        
        if (!uvm_config_db#(virtual host_ctrl_if)::get(this, "", "h_vif", env.host_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get h_vif")
        env.host_agent.monitor.vif = env.host_agent.driver.vif;

        if (!uvm_config_db#(virtual memory_if#(8,16,1))::get(this, "", "p_vif", env.prog_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get p_vif")
        env.prog_mem_agent.monitor.vif = env.prog_mem_agent.driver.vif;

        if (!uvm_config_db#(virtual memory_if#(8,8,4))::get(this, "", "d_vif", env.data_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get d_vif")
        env.data_mem_agent.monitor.vif = env.data_mem_agent.driver.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Base test started", UVM_LOW)
        #100ns;
        `uvm_info("TEST", "Base test finished", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
