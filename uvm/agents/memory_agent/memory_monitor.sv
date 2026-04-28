class memory_monitor #(
    int ADDR_BITS = 8,
    int DATA_BITS = 8,
    int NUM_CHANNELS = 1
) extends uvm_monitor;
    `uvm_component_param_utils(memory_monitor #(ADDR_BITS, DATA_BITS, NUM_CHANNELS))

    virtual memory_if #(ADDR_BITS, DATA_BITS, NUM_CHANNELS) vif;
    uvm_analysis_port #(memory_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                if (vif.read_valid[i] && vif.read_ready[i]) begin
                    memory_item item = memory_item::type_id::create("item");
                    item.op = memory_item::READ;
                    item.addr = vif.read_address[i*ADDR_BITS +: ADDR_BITS];
                    item.data = vif.read_data[i*DATA_BITS +: DATA_BITS];
                    item.channel = i;
                    ap.write(item);
                end
                if (vif.write_valid[i] && vif.write_ready[i]) begin
                    memory_item item = memory_item::type_id::create("item");
                    item.op = memory_item::WRITE;
                    item.addr = vif.write_address[i*ADDR_BITS +: ADDR_BITS];
                    item.data = vif.write_data[i*DATA_BITS +: DATA_BITS];
                    item.channel = i;
                    ap.write(item);
                end
            end
        end
    endtask
endclass
