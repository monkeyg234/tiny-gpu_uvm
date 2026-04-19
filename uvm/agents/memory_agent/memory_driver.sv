class memory_driver #(
    int ADDR_BITS = 8,
    int DATA_BITS = 8,
    int NUM_CHANNELS = 1
) extends uvm_driver #(memory_item);
    `uvm_component_param_utils(memory_driver #(ADDR_BITS, DATA_BITS, NUM_CHANNELS))

    virtual memory_if #(ADDR_BITS, DATA_BITS, NUM_CHANNELS) vif;
    logic [DATA_BITS-1:0] ram [2**ADDR_BITS-1:0];
    uvm_analysis_port #(memory_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        for (int i = 0; i < 2**ADDR_BITS; i++) ram[i] = 0;

        vif.cb.read_ready <= 0;
        vif.cb.write_ready <= 0;

        // Запускаем два процесса параллельно
        fork
            // Процесс 1: Слушаем запросы от GPU (как реальная память)
            forever begin
                @(vif.cb);
                for (int i = 0; i < NUM_CHANNELS; i++) begin
                    if (vif.cb.read_valid[i]) begin
                        vif.cb.read_data[i] <= ram[vif.cb.read_address[i]];
                        vif.cb.read_ready[i] <= 1;
                    end else begin
                        vif.cb.read_ready[i] <= 0;
                    end

                    if (vif.cb.write_valid[i]) begin
                        ram[vif.cb.write_address[i]] = vif.cb.write_data[i];
                        vif.cb.write_ready[i] <= 1;
                    end else begin
                        vif.cb.write_ready[i] <= 0;
                    end
                end
            end

            // Процесс 2: Принимаем данные от теста (предзагрузка программы/данных)
            forever begin
                seq_item_port.get_next_item(req);
                if (req.op == memory_item::WRITE) begin
                    ram[req.addr] = req.data;
                    ap.write(req);
                end
                seq_item_port.item_done();
            end
        join_none
    endtask
endclass
