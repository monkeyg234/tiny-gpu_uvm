class alu_ref;
    static function logic [7:0] compute(logic [1:0] mux, logic [7:0] rs, logic [7:0] rt);
        case (mux)
            2'b00:   return rs + rt;
            2'b01:   return rs - rt;
            2'b10:   return rs * rt;
            2'b11:   return rs / rt;
            default: return 8'h00;
        endcase
    endfunction

    static function logic [2:0] compare(logic [7:0] rs, logic [7:0] rt);
        return { ($signed(rs) > $signed(rt)), (rs == rt), ($signed(rs) < $signed(rt)) };
    endfunction
endclass
