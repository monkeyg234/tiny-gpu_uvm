`uvm_analysis_imp_decl(_host)
`uvm_analysis_imp_decl(_data_mem)

class gpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(gpu_scoreboard)

    uvm_analysis_imp_host     #(host_ctrl_item, gpu_scoreboard) host_export;
    uvm_analysis_imp_data_mem #(memory_item,    gpu_scoreboard) data_mem_export;

    logic [7:0] shadow_ram [255:0];
    int thread_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        host_export     = new("host_export", this);
        data_mem_export = new("data_mem_export", this);
        for (int i=0; i<256; i++) shadow_ram[i] = 0;
    endfunction

    virtual function void write_host(host_ctrl_item item);
        if (item.is_write) begin
            thread_count = item.data;
        end
    endfunction

    virtual function void write_data_mem(memory_item item);
        if (item.op == memory_item::WRITE) begin
            if (item.addr >= 16 && item.addr < 16 + thread_count) begin
                int idx = item.addr - 16;
                logic [7:0] expected = shadow_ram[idx] + shadow_ram[idx + 8];
                
                if (item.data === expected) begin
                    `uvm_info("SCB", $sformatf("MATCH! Addr:%0d Data:%0d", item.addr, item.data), UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("MISMATCH! Addr:%0d Got:%0d Exp:%0d", item.addr, item.data, expected))
                end
            end
            shadow_ram[item.addr] = item.data;
        end
    endfunction
endclass
