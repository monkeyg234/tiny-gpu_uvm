
class clk_agent extends uvm_agent;
    `uvm_component_utils(clk_agent)

    clk_driver               driver;
    uvm_sequencer #(clk_item) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = clk_driver::type_id::create("driver", this);
        sequencer = uvm_sequencer#(clk_item)::type_id::create("sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
