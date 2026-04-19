class gpu_matadd_seq extends uvm_sequence;
    `uvm_object_utils(gpu_matadd_seq)

    uvm_sequencer #(host_ctrl_item) host_seqr;
    uvm_sequencer #(memory_item)    prog_seqr;
    uvm_sequencer #(memory_item)    data_seqr;

    function new(string name = "gpu_matadd_seq");
        super.new(name);
    endfunction

    virtual task body();
        host_ctrl_item h_item;
        memory_item    m_item;

        logic [15:0] prog_words [] = '{
            16'h50DE, 16'h300F, 16'h9100, 16'h9208, 
            16'h9310, 16'h3410, 16'h7440, 16'h3520, 
            16'h7550, 16'h3645, 16'h3730, 16'h8076, 
            16'hF000
        };

        foreach (prog_words[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = prog_words[i];
            start_item(m_item, .sequencer(prog_seqr));
            finish_item(m_item);
        end

        for (int i=0; i<8; i++) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = i;
            start_item(m_item, .sequencer(data_seqr));
            finish_item(m_item);
            
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i + 8;
            m_item.data = i;
            start_item(m_item, .sequencer(data_seqr));
            finish_item(m_item);
        end

        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1;
        h_item.data = 8;
        start_item(h_item, .sequencer(host_seqr));
        finish_item(h_item);

        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        start_item(h_item, .sequencer(host_seqr));
        finish_item(h_item);
    endtask
endclass
