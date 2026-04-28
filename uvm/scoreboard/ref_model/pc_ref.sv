class pc_ref;

    logic [7:0] pc;
    logic [2:0] nzp;

    function new();
        pc  = 8'h0;
        nzp = 3'b000;
    endfunction

    function void reset();
        pc  = 8'h0;
        nzp = 3'b000;
    endfunction

    function logic [7:0] get_next_pc(
        logic       pc_mux,
        logic [2:0] decoded_nzp,
        logic [7:0] immediate
    );
        if (pc_mux && (nzp & decoded_nzp) != 3'b0)
            return immediate;
        else
            return pc + 1;
    endfunction

    function void update_nzp(logic nzp_write_enable, logic [2:0] new_nzp);
        if (nzp_write_enable)
            nzp = new_nzp;
    endfunction

endclass
