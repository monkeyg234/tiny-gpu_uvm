`uvm_analysis_imp_decl(_host)
`uvm_analysis_imp_decl(_data_mem)
`uvm_analysis_imp_decl(_prog_mem)
`uvm_analysis_imp_decl(_done)
`uvm_analysis_imp_decl(_rst)

class gpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(gpu_scoreboard)

    uvm_analysis_imp_host     #(host_ctrl_item, gpu_scoreboard) host_export;
    uvm_analysis_imp_data_mem #(memory_item,    gpu_scoreboard) data_mem_export;
    uvm_analysis_imp_prog_mem #(memory_item,    gpu_scoreboard) prog_mem_export;
    uvm_analysis_imp_done     #(done_item,      gpu_scoreboard) done_export;
    uvm_analysis_imp_rst      #(rst_item,       gpu_scoreboard) rst_export;

    gpu_ref_model ref_model;

    bit   kernel_started;
    bit   kernel_done;
    int   match_count;
    int   mismatch_count;
    int   total_writes;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        host_export     = new("host_export", this);
        data_mem_export = new("data_mem_export", this);
        prog_mem_export = new("prog_mem_export", this);
        done_export     = new("done_export", this);
        rst_export      = new("rst_export", this);

        ref_model = new();
        reset();
    endfunction

    virtual function void reset();
        kernel_started  = 0;
        kernel_done     = 0;
        match_count     = 0;
        mismatch_count  = 0;
        total_writes    = 0;
        if (ref_model != null) ref_model.reset();
    endfunction

    virtual function void write_host(host_ctrl_item item);
        if (item.is_write) begin
            ref_model.set_thread_count(item.data);
            `uvm_info("SCB", $sformatf("REF: thread_count = %0d", item.data), UVM_MEDIUM)
        end else if (!kernel_started) begin
            kernel_started = 1;
            `uvm_info("SCB", "REF: Kernel started", UVM_LOW)
            ref_model.execute();
        end
    endfunction

    virtual function void write_prog_mem(memory_item item);
        if (item.op == memory_item::WRITE) ref_model.load_prog(item.addr, item.data[15:0]);
    endfunction

    virtual function void write_data_mem(memory_item item);
        if (item.op == memory_item::WRITE) begin
            if (!kernel_started) begin
                ref_model.load_data(item.addr, item.data[7:0]);
                return;
            end
            total_writes++;
            if (ref_model.check_write(item.addr, item.data[7:0])) begin
                match_count++;
                `uvm_info("SCB", $sformatf("MATCH addr=0x%02h data=0x%02h", item.addr, item.data[7:0]), UVM_LOW)
            end else begin
                mismatch_count++;
                `uvm_error("SCB", $sformatf("MISMATCH addr=0x%02h actual=0x%02h expected=0x%02h", 
                    item.addr, item.data[7:0], ref_model.get_expected(item.addr)))
            end
        end
    endfunction

    virtual function void write_done(done_item item);
        if (item.value === 1'b1) begin
            kernel_done = 1;
            `uvm_info("SCB", $sformatf("Kernel done at %0t", item.timestamp), UVM_LOW)
        end
    endfunction

    virtual function void write_rst(rst_item item);
        `uvm_info("SCB", $sformatf("HW reset received (%0dns)", item.duration_ns), UVM_MEDIUM)
        if (kernel_started && !kernel_done) `uvm_info("SCB", "Reset interrupted kernel", UVM_MEDIUM)
        reset();
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (kernel_started && ref_model.executed) begin
            if (total_writes != ref_model.expected_writes.size())
                `uvm_error("SCB", $sformatf("Count mismatch: DUT=%0d, REF=%0d", 
                    total_writes, ref_model.expected_writes.size()))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "--------------------------------------------", UVM_LOW)
        `uvm_info("SCB", $sformatf("  Writes: %0d | Matches: %0d | Mismatches: %0d", 
            total_writes, match_count, mismatch_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Status: %s", (mismatch_count==0 && match_count>0) ? "PASS" : "FAIL"), UVM_LOW)
        `uvm_info("SCB", "--------------------------------------------", UVM_LOW)
    endfunction
endclass
