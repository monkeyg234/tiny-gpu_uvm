
class rst_agent extends uvm_agent;
    `uvm_component_utils(rst_agent)

    rst_driver                driver;
    rst_monitor               monitor;
    uvm_sequencer #(rst_item) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor   = rst_monitor::type_id::create("monitor", this);
        driver    = rst_driver::type_id::create("driver", this);
        sequencer = uvm_sequencer#(rst_item)::type_id::create("sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
