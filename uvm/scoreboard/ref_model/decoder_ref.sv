class decoder_ref;

    localparam logic [3:0]
        OP_NOP   = 4'b0000,
        OP_BRnzp = 4'b0001,
        OP_CMP   = 4'b0010,
        OP_ADD   = 4'b0011,
        OP_SUB   = 4'b0100,
        OP_MUL   = 4'b0101,
        OP_DIV   = 4'b0110,
        OP_LDR   = 4'b0111,
        OP_STR   = 4'b1000,
        OP_CONST = 4'b1001,
        OP_RET   = 4'b1111;

    typedef struct {
        logic [3:0] opcode;
        logic [3:0] rd_addr;
        logic [3:0] rs_addr;
        logic [3:0] rt_addr;
        logic [7:0] immediate;
        logic [2:0] nzp;

        logic       reg_write_enable;
        logic       mem_read_enable;
        logic       mem_write_enable;
        logic       nzp_write_enable;
        logic [1:0] reg_input_mux;
        logic [1:0] alu_arithmetic_mux;
        logic       alu_output_mux;
        logic       pc_mux;
        logic       is_ret;
    } decoded_instr_t;

    static function decoded_instr_t decode(logic [15:0] instruction);
        decoded_instr_t d;

        d.opcode    = instruction[15:12];
        d.rd_addr   = instruction[11:8];
        d.rs_addr   = instruction[7:4];
        d.rt_addr   = instruction[3:0];
        d.immediate = instruction[7:0];
        d.nzp       = instruction[11:9];

        d.reg_write_enable   = 0;
        d.mem_read_enable    = 0;
        d.mem_write_enable   = 0;
        d.nzp_write_enable   = 0;
        d.reg_input_mux      = 2'b00;
        d.alu_arithmetic_mux = 2'b00;
        d.alu_output_mux     = 0;
        d.pc_mux             = 0;
        d.is_ret             = 0;

        case (d.opcode)
            OP_NOP: ;
            OP_BRnzp: begin
                d.pc_mux = 1;
            end
            OP_CMP: begin
                d.alu_output_mux   = 1;
                d.nzp_write_enable = 1;
            end
            OP_ADD: begin
                d.reg_write_enable   = 1;
                d.reg_input_mux      = 2'b00;
                d.alu_arithmetic_mux = 2'b00;
            end
            OP_SUB: begin
                d.reg_write_enable   = 1;
                d.reg_input_mux      = 2'b00;
                d.alu_arithmetic_mux = 2'b01;
            end
            OP_MUL: begin
                d.reg_write_enable   = 1;
                d.reg_input_mux      = 2'b00;
                d.alu_arithmetic_mux = 2'b10;
            end
            OP_DIV: begin
                d.reg_write_enable   = 1;
                d.reg_input_mux      = 2'b00;
                d.alu_arithmetic_mux = 2'b11;
            end
            OP_LDR: begin
                d.reg_write_enable = 1;
                d.reg_input_mux    = 2'b01;
                d.mem_read_enable  = 1;
            end
            OP_STR: begin
                d.mem_write_enable = 1;
            end
            OP_CONST: begin
                d.reg_write_enable = 1;
                d.reg_input_mux    = 2'b10;
            end
            OP_RET: begin
                d.is_ret = 1;
            end
            default: ;
        endcase

        return d;
    endfunction

endclass
