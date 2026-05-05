class gpu_base_vseq extends uvm_sequence;
    `uvm_object_utils(gpu_base_vseq)
    `uvm_declare_p_sequencer(gpu_virtual_sequencer)

    function new(string name = "gpu_base_vseq");
        super.new(name);
    endfunction

    virtual task load_program(logic [15:0] prog[$]);
        foreach (prog[i]) begin
            memory_item m = memory_item::type_id::create("m");
            m.op = memory_item::WRITE; m.addr = i; m.data = prog[i];
            p_sequencer.prog_seqr.execute_item(m);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d words", prog.size()), UVM_MEDIUM)
    endtask

    virtual task load_data(int base_addr, logic [7:0] data[$]);
        foreach (data[i]) begin
            memory_item m = memory_item::type_id::create("m");
            m.op = memory_item::WRITE; m.addr = base_addr + i; m.data = data[i];
            p_sequencer.data_seqr.execute_item(m);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d bytes at 0x%02h", data.size(), base_addr), UVM_MEDIUM)
    endtask

    virtual task launch_kernel(int thread_count);
        host_ctrl_item h;
        h = host_ctrl_item::type_id::create("h");
        h.is_write = 1; h.data = thread_count;
        p_sequencer.host_seqr.execute_item(h);

        h = host_ctrl_item::type_id::create("h2");
        h.is_write = 0;
        p_sequencer.host_seqr.execute_item(h);
        `uvm_info("VSEQ", $sformatf("Launched %0d threads", thread_count), UVM_LOW)
    endtask

    virtual task clear_start();
        host_ctrl_item h = host_ctrl_item::type_id::create("h");
        h.is_start_clear = 1;
        p_sequencer.host_seqr.execute_item(h);
    endtask
endclass
