// gpu_base_vseq.sv — Базовая виртуальная последовательность.
// Предоставляет общие утилиты (загрузка программы, загрузка данных, запуск kernel),
// которые переиспользуются всеми тестовыми последовательностями.
class gpu_base_vseq extends uvm_sequence;
    `uvm_object_utils(gpu_base_vseq)
    `uvm_declare_p_sequencer(gpu_virtual_sequencer)

    function new(string name = "gpu_base_vseq");
        super.new(name);
    endfunction

    // -------------------------------------------------------
    // Утилита: загрузить программу в память инструкций
    // -------------------------------------------------------
    virtual task load_program(logic [15:0] prog[$]);
        memory_item m_item;
        foreach (prog[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op   = memory_item::WRITE;
            m_item.addr = i;
            m_item.data = prog[i];
            p_sequencer.prog_seqr.execute_item(m_item);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d program words", prog.size()), UVM_MEDIUM)
    endtask

    // -------------------------------------------------------
    // Утилита: загрузить данные в память данных
    // -------------------------------------------------------
    virtual task load_data(int base_addr, logic [7:0] data[$]);
        memory_item m_item;
        foreach (data[i]) begin
            m_item = memory_item::type_id::create("m_item");
            m_item.op   = memory_item::WRITE;
            m_item.addr = base_addr + i;
            m_item.data = data[i];
            p_sequencer.data_seqr.execute_item(m_item);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d data bytes at base 0x%02h", data.size(), base_addr), UVM_MEDIUM)
    endtask

    // -------------------------------------------------------
    // Утилита: настроить DCR и запустить kernel
    // -------------------------------------------------------
    virtual task launch_kernel(int thread_count);
        host_ctrl_item h_item;

        // DCR write — установить количество потоков
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 1;
        h_item.data = thread_count;
        p_sequencer.host_seqr.execute_item(h_item);

        // Start — запустить выполнение
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_write = 0;
        p_sequencer.host_seqr.execute_item(h_item);

        `uvm_info("VSEQ", $sformatf("Kernel launched with %0d threads", thread_count), UVM_LOW)
    endtask

    // -------------------------------------------------------
    // Утилита: сбросить сигнал start
    // -------------------------------------------------------
    virtual task clear_start();
        host_ctrl_item h_item;
        h_item = host_ctrl_item::type_id::create("h_item");
        h_item.is_start_clear = 1;
        p_sequencer.host_seqr.execute_item(h_item);
    endtask
endclass
