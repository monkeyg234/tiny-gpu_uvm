class memory_item extends uvm_sequence_item;
    `uvm_object_utils(memory_item)

    typedef enum {READ, WRITE} op_e;

    rand op_e          op;
    rand logic [7:0]   addr;
    rand logic [15:0]  data;
    rand int           channel;

    function new(string name = "memory_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("op=%s addr=0x%0h data=0x%0h channel=%0d", op.name(), addr, data, channel);
    endfunction
endclass
