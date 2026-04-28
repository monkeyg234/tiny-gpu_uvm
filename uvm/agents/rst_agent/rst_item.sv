
class rst_item extends uvm_sequence_item;
    `uvm_object_utils(rst_item)

    rand int unsigned duration_ns;

    constraint c_valid   { duration_ns > 0; }
    constraint c_default { soft duration_ns == 20; }

    function new(string name = "rst_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("duration=%0dns", duration_ns);
    endfunction
endclass
