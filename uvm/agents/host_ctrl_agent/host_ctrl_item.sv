class host_ctrl_item extends uvm_sequence_item;
    `uvm_object_utils(host_ctrl_item)

    rand logic [7:0] data;
    rand logic       is_write;

    function new(string name = "host_ctrl_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("is_write=%0b data=0x%0h", is_write, data);
    endfunction
endclass
