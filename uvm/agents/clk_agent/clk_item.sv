
class clk_item extends uvm_sequence_item;
    `uvm_object_utils(clk_item)

    rand int unsigned period_ns;

    constraint c_valid  { period_ns >= 2; period_ns % 2 == 0; }
    constraint c_default { soft period_ns == 10; }

    function new(string name = "clk_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("period=%0dns", period_ns);
    endfunction
endclass
