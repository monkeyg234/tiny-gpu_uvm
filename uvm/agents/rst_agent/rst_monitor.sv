
class rst_monitor extends uvm_monitor;
    `uvm_component_utils(rst_monitor)

    virtual rst_agent_if vif;
    uvm_analysis_port #(rst_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            rst_item item;
            time rst_begin, rst_end;

  
            @(posedge vif.reset);
            rst_begin = $time;
            `uvm_info("RST_MON", "Reset asserted", UVM_HIGH)

            
            @(negedge vif.reset);
            rst_end = $time;

            item = rst_item::type_id::create("rst_item");
            item.duration_ns = int'(rst_end - rst_begin);
            `uvm_info("RST_MON", $sformatf("Reset deasserted, duration=%0dns", item.duration_ns), UVM_MEDIUM)
            ap.write(item);
        end
    endtask
endclass
