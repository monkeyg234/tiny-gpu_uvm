
class done_monitor extends uvm_monitor;
    `uvm_component_utils(done_monitor)

    virtual done_agent_if vif;
    uvm_analysis_port #(done_item) ap;

  
    uvm_event done_event;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        done_event = new("done_event");
    endfunction

    virtual task run_phase(uvm_phase phase);

        wait (!$isunknown(vif.done));

        forever begin
            done_item item;
            @(posedge vif.done or negedge vif.done);
            item = done_item::type_id::create("done_item");
            item.value     = vif.done;
            item.timestamp = $time;

            if (vif.done === 1'b1) begin
                `uvm_info("DONE_MON", $sformatf("GPU done asserted at %0t", $time), UVM_LOW)
                done_event.trigger();
            end else begin
                `uvm_info("DONE_MON", $sformatf("GPU done deasserted at %0t", $time), UVM_MEDIUM)
                done_event.reset();
            end

            ap.write(item);
        end
    endtask

    task wait_for_done();
        if (vif.done !== 1'b1)
            done_event.wait_trigger();
    endtask
endclass
