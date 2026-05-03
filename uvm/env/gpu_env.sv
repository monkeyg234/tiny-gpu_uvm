class gpu_env extends uvm_env;
    `uvm_component_utils(gpu_env)

    // Configuration object
    gpu_env_cfg cfg;

    clk_agent              clk_ag;
    rst_agent              rst_ag;

    host_ctrl_agent        host_agent;
    memory_agent #(8, 16, 1) prog_mem_agent;
    memory_agent #(8, 8, 4)  data_mem_agent;

    done_agent             done_ag;

    // Virtual sequencer for coordinating multiple agents
    gpu_virtual_sequencer  v_seqr;

    gpu_scoreboard         scoreboard;
    gpu_coverage           coverage_col;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get or create configuration
        if (!uvm_config_db#(gpu_env_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_info("ENV", "No gpu_env_cfg found in config_db, using defaults", UVM_MEDIUM)
            cfg = gpu_env_cfg::type_id::create("cfg");
        end

        // Infrastructure agents
        clk_ag  = clk_agent::type_id::create("clk_ag", this);
        rst_ag  = rst_agent::type_id::create("rst_ag", this);

        // Protocol agents
        host_agent     = host_ctrl_agent::type_id::create("host_agent", this);
        prog_mem_agent = memory_agent #(8, 16, 1)::type_id::create("prog_mem_agent", this);
        data_mem_agent = memory_agent #(8, 8, 4)::type_id::create("data_mem_agent", this);

        // Passive agent
        done_ag = done_agent::type_id::create("done_ag", this);

        // Virtual sequencer
        v_seqr = gpu_virtual_sequencer::type_id::create("v_seqr", this);

        // Scoreboard (conditionally)
        if (cfg.en_scoreboard)
            scoreboard = gpu_scoreboard::type_id::create("scoreboard", this);

        // Coverage (conditionally)
        if (cfg.en_coverage)
            coverage_col = gpu_coverage::type_id::create("coverage_col", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Scoreboard connections
        if (cfg.en_scoreboard) begin
            host_agent.monitor.ap.connect(scoreboard.host_export);
            data_mem_agent.monitor.ap.connect(scoreboard.data_mem_export);
            prog_mem_agent.driver.ap.connect(scoreboard.prog_mem_export);
            data_mem_agent.driver.ap.connect(scoreboard.data_mem_export);
            done_ag.monitor.ap.connect(scoreboard.done_export);
        end

        // Coverage connections
        if (cfg.en_coverage) begin
            host_agent.monitor.ap.connect(coverage_col.host_export);
            prog_mem_agent.driver.ap.connect(coverage_col.prog_mem_export);
            data_mem_agent.monitor.ap.connect(coverage_col.data_mem_export);
        end

        // Virtual sequencer wiring
        v_seqr.host_seqr = host_agent.sequencer;
        v_seqr.prog_seqr = prog_mem_agent.sequencer;
        v_seqr.data_seqr = data_mem_agent.sequencer;
    endfunction
endclass
