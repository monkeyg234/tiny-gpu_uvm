class host_ctrl_driver extends uvm_driver #(host_ctrl_item);
    `uvm_component_utils(host_ctrl_driver)

    virtual host_ctrl_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.cb.start <= 0;
        vif.cb.device_control_write_enable <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(host_ctrl_item item);
        @(vif.cb);
        if (item.is_write) begin
            vif.cb.device_control_data <= item.data;
            vif.cb.device_control_write_enable <= 1;
            @(vif.cb);
            vif.cb.device_control_write_enable <= 0;
        end else begin
            vif.cb.start <= 1;
            @(vif.cb);
            vif.cb.start <= 0;
        end
    endtask
endclass
