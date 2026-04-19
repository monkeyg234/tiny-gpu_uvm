class memory_agent #(
    int ADDR_BITS = 8,
    int DATA_BITS = 8,
    int NUM_CHANNELS = 1
) extends uvm_agent;
    `uvm_component_param_utils(memory_agent #(ADDR_BITS, DATA_BITS, NUM_CHANNELS))

    memory_driver    #(ADDR_BITS, DATA_BITS, NUM_CHANNELS) driver;
    memory_monitor   #(ADDR_BITS, DATA_BITS, NUM_CHANNELS) monitor;
    uvm_sequencer    #(memory_item) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = memory_monitor #(ADDR_BITS, DATA_BITS, NUM_CHANNELS)::type_id::create("monitor", this);
        driver = memory_driver #(ADDR_BITS, DATA_BITS, NUM_CHANNELS)::type_id::create("driver", this);
        sequencer = uvm_sequencer #(memory_item)::type_id::create("sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
