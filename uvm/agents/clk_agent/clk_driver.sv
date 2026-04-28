
class clk_driver extends uvm_driver #(clk_item);
    `uvm_component_utils(clk_driver)

    virtual clk_agent_if vif;
    int unsigned half_period = 5; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.clk = 0;
        fork
           
            forever begin
                #(half_period * 1ns);
                vif.clk = ~vif.clk;
            end
       
            forever begin
                seq_item_port.get_next_item(req);
                if (req.period_ns >= 2 && req.period_ns % 2 == 0) begin
                    half_period = req.period_ns / 2;
                    `uvm_info("CLK_DRV", $sformatf("Clock period changed to %0dns", req.period_ns), UVM_MEDIUM)
                end else begin
                    `uvm_warning("CLK_DRV", $sformatf("Invalid period %0d — ignored", req.period_ns))
                end
                seq_item_port.item_done();
            end
        join
    endtask
endclass
