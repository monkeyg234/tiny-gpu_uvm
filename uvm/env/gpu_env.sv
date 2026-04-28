class gpu_env extends uvm_env;
    `uvm_component_utils(gpu_env)


    clk_agent              clk_ag;
    rst_agent              rst_ag;

    host_ctrl_agent        host_agent;
    memory_agent #(8, 16, 1) prog_mem_agent;
    memory_agent #(8, 8, 4)  data_mem_agent;

   
    done_agent             done_ag;

 
    gpu_scoreboard         scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Infrastructure agents
        clk_ag  = clk_agent::type_id::create("clk_ag", this);
        rst_ag  = rst_agent::type_id::create("rst_ag", this);

        // Protocol agents
        host_agent     = host_ctrl_agent::type_id::create("host_agent", this);
        prog_mem_agent = memory_agent #(8, 16, 1)::type_id::create("prog_mem_agent", this);
        data_mem_agent = memory_agent #(8, 8, 4)::type_id::create("data_mem_agent", this);

        // Passive agent
        done_ag = done_agent::type_id::create("done_ag", this);

        // Scoreboard
        scoreboard = gpu_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        host_agent.monitor.ap.connect(scoreboard.host_export);
        data_mem_agent.monitor.ap.connect(scoreboard.data_mem_export);

        prog_mem_agent.driver.ap.connect(scoreboard.prog_mem_export);
        data_mem_agent.driver.ap.connect(scoreboard.data_mem_export);

        
        done_ag.monitor.ap.connect(scoreboard.done_export);
    endfunction
endclass
