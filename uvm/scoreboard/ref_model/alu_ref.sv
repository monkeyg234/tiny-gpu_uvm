class alu_ref;

    static function logic [7:0] compute(
        logic [1:0] alu_arithmetic_mux,
        logic [7:0] rs,
        logic [7:0] rt
    );
        case (alu_arithmetic_mux)
            2'b00:   return rs + rt;
            2'b01:   return rs - rt;
            2'b10:   return rs * rt;
            2'b11:   return rs / rt;
            default: return 8'h00;
        endcase
    endfunction

    static function logic [2:0] compare(logic [7:0] rs, logic [7:0] rt);
        // ПРАВИЛЬНАЯ эталонная модель (по спецификации):
        return { 
            ($signed(rs) > $signed(rt)), 
            (rs == rt), 
            ($signed(rs) < $signed(rt)) 
        };

        /*
        // НЕПРАВИЛЬНАЯ модель (bug-for-bug совместимость с багом RTL):
        // Раскомментируйте этот блок и закомментируйте правильный, если нужно
        // чтобы Scoreboard игнорировал баг с зависшим флагом Negative.
        logic [7:0] diff;
        diff = rs - rt;
        return {(diff > 0), (diff == 0), 1'b0};
        */
    endfunction

endclass
