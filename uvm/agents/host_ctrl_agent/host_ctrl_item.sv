class host_ctrl_item extends uvm_sequence_item;
    `uvm_object_utils_begin(host_ctrl_item)
        `uvm_field_int(data,           UVM_ALL_ON)
        `uvm_field_int(is_write,       UVM_ALL_ON)
        `uvm_field_int(is_start_clear, UVM_ALL_ON)
    `uvm_object_utils_end

    rand logic [7:0] data;
    rand logic       is_write;
    rand logic       is_start_clear;

    constraint c_defaults {
        is_start_clear == 0; 
    }

    function new(string name = "host_ctrl_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("is_write=%0b is_start_clear=%0b data=0x%0h", is_write, is_start_clear, data);
    endfunction
endclass

