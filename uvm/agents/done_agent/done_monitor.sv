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
        fork
            // Process 1: done signal tracking
            forever begin
                done_item item;
                @(posedge vif.done or negedge vif.done);
                item = done_item::type_id::create("item");
                item.value = vif.done;
                item.timestamp = $time;

                if (vif.done === 1'b1) begin
                    `uvm_info("DONE_MON", "GPU done asserted", UVM_LOW)
                    done_event.trigger();
                end else begin
                    done_event.reset();
                end
                ap.write(item);
            end
            // Process 2: HW reset clearing
            forever begin
                @(posedge vif.reset);
                if (done_event.is_on()) done_event.reset();
            end
        join_none
    endtask

    task wait_for_done();
        @(posedge vif.done);
    endtask
endclass
