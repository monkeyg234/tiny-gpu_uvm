class core_ref;

    regfile_ref regfiles[];
    pc_ref      pcs[];

    int threads_per_block;
    int active_threads;

    typedef struct {
        logic [7:0] addr;
        logic [7:0] data;
    } mem_write_t;

    mem_write_t mem_writes[$];

    function new(int tpb = 4);
        threads_per_block = tpb;
        regfiles = new[tpb];
        pcs      = new[tpb];
        for (int i = 0; i < tpb; i++) begin
            regfiles[i] = new(i, tpb);
            pcs[i]      = new();
        end
    endfunction

    function void execute_block(
        logic [7:0]  block_id,
        int          thread_count,
        ref logic [15:0] prog_mem [256],
        ref logic [7:0]  data_mem [256]
    );
        decoder_ref::decoded_instr_t d;
        logic [7:0] current_pc;
        int max_instructions = 1000;
        int instr_count = 0;

        active_threads = thread_count;
        mem_writes.delete();

        for (int t = 0; t < threads_per_block; t++) begin
            regfiles[t].reset(block_id);
            pcs[t].reset();
        end

        current_pc = 0;

        while (instr_count < max_instructions) begin
            logic [15:0] instruction;

            instr_count++;

            instruction = prog_mem[current_pc];

            d = decoder_ref::decode(instruction);

            if (d.is_ret)
                break;

            for (int t = 0; t < active_threads; t++) begin
                logic [7:0] rs_val, rt_val, alu_out, lsu_out;

                rs_val = regfiles[t].read(d.rs_addr);
                rt_val = regfiles[t].read(d.rt_addr);

                if (d.alu_output_mux)
                    alu_out = {5'b0, alu_ref::compare(rs_val, rt_val)};
                else
                    alu_out = alu_ref::compute(d.alu_arithmetic_mux, rs_val, rt_val);

                if (d.mem_read_enable)
                    lsu_out = data_mem[rs_val];

                if (d.mem_write_enable) begin
                    mem_write_t mw;
                    data_mem[rs_val] = rt_val;
                    mw.addr = rs_val;
                    mw.data = rt_val;
                    mem_writes.push_back(mw);
                end

                pcs[t].pc = pcs[t].get_next_pc(d.pc_mux, d.nzp, d.immediate);

                if (d.reg_write_enable) begin
                    case (d.reg_input_mux)
                        2'b00:   regfiles[t].write(d.rd_addr, alu_out);
                        2'b01:   regfiles[t].write(d.rd_addr, lsu_out);
                        2'b10:   regfiles[t].write(d.rd_addr, d.immediate);
                        default: ;
                    endcase
                end

                pcs[t].update_nzp(d.nzp_write_enable, alu_out[2:0]);
            end

            // ПРАВИЛЬНАЯ эталонная модель (по спецификации):
            // Берем PC у последнего АКТИВНОГО потока, чтобы избежать зависаний
            if (active_threads == threads_per_block)
                current_pc = pcs[threads_per_block - 1].pc;
            else
                current_pc = pcs[active_threads - 1].pc;

            /*
            // НЕПРАВИЛЬНАЯ модель (bug-for-bug совместимость с багом RTL):
            // В RTL всегда берется последний поток в блоке, даже если он выключен.
            // Раскомментируйте эту строку, если хотите, чтобы эталонная модель
            // тоже зависала (уходила в бесконечный цикл) так же, как и сам GPU.
            // current_pc = pcs[threads_per_block - 1].pc;
            */
        end

    endfunction

endclass
