class host_ctrl_monitor extends uvm_monitor;
    `uvm_component_utils(host_ctrl_monitor)

    virtual host_ctrl_if vif;
    uvm_analysis_port #(host_ctrl_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        
        @(negedge vif.reset);

        fork
            monitor_dcr_writes();
            monitor_start();
        join
    endtask

   
    virtual task monitor_dcr_writes();
        forever begin
            @(posedge vif.clk);
            if (vif.device_control_write_enable) begin
                host_ctrl_item item = host_ctrl_item::type_id::create("item");
                item.is_write = 1;
                item.data     = vif.device_control_data;
                `uvm_info("HOST_MON", $sformatf("DCR write: data=0x%02h", item.data), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask

    
    virtual task monitor_start();
        forever begin
            @(posedge vif.start);
            begin
                host_ctrl_item item = host_ctrl_item::type_id::create("item");
                item.is_write = 0;   // is_write=0 means "start"
                item.data     = 0;
                `uvm_info("HOST_MON", "Start signal detected", UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask
endclass
