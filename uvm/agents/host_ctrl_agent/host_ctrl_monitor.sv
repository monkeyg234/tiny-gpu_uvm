class host_ctrl_monitor extends uvm_monitor;
    `uvm_component_utils(host_ctrl_monitor)

    virtual host_ctrl_if vif;
    uvm_analysis_port #(host_ctrl_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            host_ctrl_item item;
            @(posedge vif.clk);
            if (vif.device_control_write_enable) begin
                item = host_ctrl_item::type_id::create("item");
                item.is_write = 1;
                item.data = vif.device_control_data;
                ap.write(item);
            end
        end
    endtask
endclass
