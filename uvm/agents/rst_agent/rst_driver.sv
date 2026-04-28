
class rst_driver extends uvm_driver #(rst_item);
    `uvm_component_utils(rst_driver)

    virtual rst_agent_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.reset <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_reset(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_reset(rst_item item);
        `uvm_info("RST_DRV", $sformatf("Asserting reset for %0dns", item.duration_ns), UVM_MEDIUM)
        vif.reset <= 1;
        #(item.duration_ns * 1ns);
        vif.reset <= 0;
        `uvm_info("RST_DRV", "Reset deasserted", UVM_MEDIUM)
    endtask
endclass
