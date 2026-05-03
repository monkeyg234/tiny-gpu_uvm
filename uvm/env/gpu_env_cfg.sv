
class gpu_env_cfg extends uvm_object;
    `uvm_object_utils(gpu_env_cfg)

    // -------------------------------------------------------
    // Timeout configuration
    // -------------------------------------------------------
    int unsigned watchdog_timeout_ns = 2_000_000; 
    int unsigned post_done_drain_ns  = 100;       

    // -------------------------------------------------------
    // Agent activity modes
    // -------------------------------------------------------
    uvm_active_passive_enum host_agent_is_active     = UVM_ACTIVE;
    uvm_active_passive_enum prog_mem_agent_is_active = UVM_ACTIVE;
    uvm_active_passive_enum data_mem_agent_is_active = UVM_ACTIVE;

    // -------------------------------------------------------
    // Coverage enables
    // -------------------------------------------------------
    bit en_coverage   = 1;
    bit en_scoreboard = 1;

    // -------------------------------------------------------
    // Scoreboard configuration
    // -------------------------------------------------------
    bit check_write_count = 1;  // Проверять совпадение количества записей

    function new(string name = "gpu_env_cfg");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf({
            "gpu_env_cfg:\n",
            "  watchdog_timeout_ns  = %0d\n",
            "  post_done_drain_ns   = %0d\n",
            "  en_coverage          = %0b\n",
            "  en_scoreboard        = %0b\n",
            "  check_write_count    = %0b"},
            watchdog_timeout_ns, post_done_drain_ns,
            en_coverage, en_scoreboard, check_write_count);
    endfunction
endclass
