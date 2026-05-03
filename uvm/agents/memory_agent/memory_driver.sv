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

        fork
            // Процесс 1: Слушаем запросы от GPU (как реальная память)
            forever begin
                logic [NUM_CHANNELS*DATA_BITS-1:0] next_read_data = 0;
                logic [NUM_CHANNELS-1:0] next_read_ready = 0;
                logic [NUM_CHANNELS-1:0] next_write_ready = 0;
                
                @(vif.cb);
                for (int i = 0; i < NUM_CHANNELS; i++) begin
                    if (vif.cb.read_valid[i]) begin
                        next_read_data[i*DATA_BITS +: DATA_BITS] = ram[vif.cb.read_address[i*ADDR_BITS +: ADDR_BITS]];
                        next_read_ready[i] = 1;
                    end else begin
                        next_read_ready[i] = 0;
                    end

                    if (vif.cb.write_valid[i]) begin
                        ram[vif.cb.write_address[i*ADDR_BITS +: ADDR_BITS]] = vif.cb.write_data[i*DATA_BITS +: DATA_BITS];
                        next_write_ready[i] = 1;
                    end else begin
                        next_write_ready[i] = 0;
                    end
                end
                vif.cb.read_data <= next_read_data;
                vif.cb.read_ready <= next_read_ready;
                vif.cb.write_ready <= next_write_ready;
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
