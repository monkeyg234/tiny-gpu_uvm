
class done_item extends uvm_sequence_item;
    `uvm_object_utils(done_item)

    logic value;     
    time  timestamp;   

    function new(string name = "done_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("done=%0b time=%0t", value, timestamp);
    endfunction
endclass
