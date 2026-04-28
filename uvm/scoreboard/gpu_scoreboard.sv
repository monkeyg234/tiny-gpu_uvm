`uvm_analysis_imp_decl(_host)
`uvm_analysis_imp_decl(_data_mem)
`uvm_analysis_imp_decl(_prog_mem)
`uvm_analysis_imp_decl(_done)

class gpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(gpu_scoreboard)

    // Analysis exports — receive transactions from monitors
    uvm_analysis_imp_host     #(host_ctrl_item, gpu_scoreboard) host_export;
    uvm_analysis_imp_data_mem #(memory_item,    gpu_scoreboard) data_mem_export;
    uvm_analysis_imp_prog_mem #(memory_item,    gpu_scoreboard) prog_mem_export;
    uvm_analysis_imp_done     #(done_item,      gpu_scoreboard) done_export;

    // ----- Reference Model (эталонная модель) -----
    gpu_ref_model ref_model;

    // Scoreboard state
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

        // Create reference model
        ref_model = new();
        reset();
    endfunction

    // -------------------------------------------------------
    // Reset state for multiple iterations
    // -------------------------------------------------------
    virtual function void reset();
        kernel_started  = 0;
        kernel_done     = 0;
        match_count     = 0;
        mismatch_count  = 0;
        total_writes    = 0;
        if (ref_model != null) ref_model.reset();
    endfunction

    // -------------------------------------------------------
    // Host Control transactions → reference model
    // -------------------------------------------------------
    virtual function void write_host(host_ctrl_item item);
        if (item.is_write) begin
            // DCR write — set thread count in reference model
            ref_model.set_thread_count(item.data);
            `uvm_info("SCB", $sformatf("REF: thread_count = %0d", item.data), UVM_MEDIUM)
        end else begin
            // Start signal — execute reference model
            if (!kernel_started) begin
                kernel_started = 1;
                `uvm_info("SCB", "REF: Kernel started — executing reference model", UVM_LOW)
                ref_model.execute();
                `uvm_info("SCB", $sformatf("REF: Reference model computed %0d expected writes",
                    ref_model.expected_writes.size()), UVM_LOW)
            end
        end
    endfunction

    // -------------------------------------------------------
    // Program Memory preload → reference model
    // -------------------------------------------------------
    virtual function void write_prog_mem(memory_item item);
        if (item.op == memory_item::WRITE) begin
            ref_model.load_prog(item.addr, item.data[15:0]);
        end
    endfunction

    // -------------------------------------------------------
    // Data Memory transactions → compare against reference model
    // -------------------------------------------------------
    virtual function void write_data_mem(memory_item item);
        if (item.op == memory_item::WRITE) begin

            // Phase 1: preload (before kernel start) → feed to reference model
            if (!kernel_started) begin
                ref_model.load_data(item.addr, item.data[7:0]);
                return;
            end

            // Phase 2: DUT runtime writes → compare against reference model
            total_writes++;
            if (ref_model.check_write(item.addr, item.data[7:0])) begin
                match_count++;
                `uvm_info("SCB", $sformatf("MATCH  addr=0x%02h  data=0x%02h (expected=0x%02h)",
                    item.addr, item.data[7:0],
                    ref_model.get_expected(item.addr)), UVM_LOW)
            end else begin
                mismatch_count++;
                `uvm_error("SCB", $sformatf("MISMATCH  addr=0x%02h  actual=0x%02h  expected=0x%02h",
                    item.addr, item.data[7:0],
                    ref_model.get_expected(item.addr)))
            end
        end
    endfunction

    // -------------------------------------------------------
    // Done signal
    // -------------------------------------------------------
    virtual function void write_done(done_item item);
        if (item.value === 1'b1) begin
            kernel_done = 1;
            `uvm_info("SCB", $sformatf("Kernel done at %0t", item.timestamp), UVM_LOW)
        end
    endfunction

    // -------------------------------------------------------
    // Final report
    // -------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "============================================", UVM_LOW)
        `uvm_info("SCB", "        SCOREBOARD SUMMARY", UVM_LOW)
        `uvm_info("SCB", "============================================", UVM_LOW)
        `uvm_info("SCB", $sformatf("  Total DUT writes   : %0d", total_writes), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Matches            : %0d", match_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Mismatches         : %0d", mismatch_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Kernel completed   : %s", kernel_done ? "YES" : "NO"), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Reference executed : %s", ref_model.executed ? "YES" : "NO"), UVM_LOW)
        `uvm_info("SCB", "============================================", UVM_LOW)

        if (mismatch_count > 0)
            `uvm_error("SCB", $sformatf("FAIL — %0d mismatches detected", mismatch_count))
        else if (match_count > 0)
            `uvm_info("SCB", "PASS — all DUT writes match reference model", UVM_LOW)
        else
            `uvm_warning("SCB", "No DUT writes observed to verify")

        if (!kernel_done)
            `uvm_warning("SCB", "Kernel did NOT complete (done never asserted)")
    endfunction

endclass
