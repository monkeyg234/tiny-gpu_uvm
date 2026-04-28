class gpu_stress_seq extends uvm_sequence;
    `uvm_object_utils(gpu_stress_seq)

    uvm_sequencer #(host_ctrl_item) host_seqr;
    uvm_sequencer #(memory_item)    prog_seqr;
    uvm_sequencer #(memory_item)    data_seqr;

    rand int num_threads;
    
    constraint c_threads {
        num_threads inside {[1:8]}; // От 1 до 8 потоков (включая неполные блоки)
    }

    function new(string name = "gpu_stress_seq");
        super.new(name);
    endfunction

    virtual task body();
        host_ctrl_item h_item;
        memory_item    m_item;

        // Та же программа MatAdd, но теперь для случайного числа потоков
        logic [15:0] prog_words [] = '{
            16'h50DE, 16'h300F, 16'h9100, 16'h9208, 
            16'h9310, 16'h3410, 16'h7440, 16'h3520, 
            16'h7550, 16'h3645, 16'h3730, 16'h8076, 
            16'hF000
        };

        // Загрузка программы
        foreach (prog_words[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = prog_words[i];
            start_item(m_item, .sequencer(prog_seqr));
            finish_item(m_item);
        end

        // Инициализация данных
        for (int i=0; i<8; i++) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = i + $urandom_range(0, 10); // Немного случайности
            start_item(m_item, .sequencer(data_seqr));
            finish_item(m_item);
            
            m_item = memory_item::type_id::create("m_item");
            m_item.op = memory_item::WRITE;
            m_item.addr = i + 8;
            m_item.data = i + $urandom_range(0, 10); // Немного случайности
            start_item(m_item, .sequencer(data_seqr));
            finish_item(m_item);
        end

        // Настройка DCR (Количество потоков)
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1;
        h_item.data = num_threads;
        start_item(h_item, .sequencer(host_seqr));
        finish_item(h_item);

        // Запуск
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        start_item(h_item, .sequencer(host_seqr));
        finish_item(h_item);
    endtask
endclass
