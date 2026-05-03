// gpu_coverage.sv — Функциональное покрытие верификации GPU.
// Собирает покрытие по:
//   - Конфигурации запуска (thread_count)
//   - ISA-опкодам (все инструкции)
//   - ALU-операциям
//   - Паттернам доступа к памяти
//   - Кросс-покрытие (opcode × thread_count)
//
// Подключается как subscriber к host_ctrl_agent.monitor.ap
// и дополнительно к data_mem_agent.monitor.ap для memory coverage.

class gpu_coverage extends uvm_component;
    `uvm_component_utils(gpu_coverage)

    // Analysis exports для приёма транзакций
    uvm_analysis_imp_host     #(host_ctrl_item, gpu_coverage) host_export;
    uvm_analysis_imp_data_mem #(memory_item,    gpu_coverage) data_mem_export;
    uvm_analysis_imp_prog_mem #(memory_item,    gpu_coverage) prog_mem_export;

    // Локальные данные для сэмплирования
    int          sampled_thread_count;
    logic [3:0]  sampled_opcode;
    logic [7:0]  sampled_mem_addr;
    logic [7:0]  sampled_mem_data;
    bit          sampled_is_read;
    bit          sampled_is_write;
    int          kernel_count;
    bit          kernel_active;

    // -------------------------------------------------------
    // 1. Покрытие конфигурации запуска kernel
    // -------------------------------------------------------
    covergroup cg_kernel_config;
        cp_thread_count: coverpoint sampled_thread_count {
            bins single       = {1};
            bins partial_blk  = {[2:3]};        // Неполный блок (<THREADS_PER_BLOCK)
            bins one_full_blk = {4};             // Ровно 1 полный блок
            bins multi_partial = {[5:7]};        // Несколько блоков, последний неполный
            bins two_full_blk = {8};             // Ровно 2 полных блока
            bins many_threads = {[9:$]};         // Больше 2 блоков
        }
    endgroup

    // -------------------------------------------------------
    // 2. Покрытие ISA — все опкоды
    // -------------------------------------------------------
    covergroup cg_isa;
        cp_opcode: coverpoint sampled_opcode {
            bins nop   = {4'h0};
            bins br    = {4'h1};
            bins cmp   = {4'h2};
            bins add   = {4'h3};
            bins sub   = {4'h4};
            bins mul   = {4'h5};
            bins div   = {4'h6};
            bins ldr   = {4'h7};
            bins str   = {4'h8};
            bins cnst  = {4'h9};
            bins ret   = {4'hF};
            bins unused[] = default;
        }
    endgroup

    // -------------------------------------------------------
    // 3. Покрытие паттернов доступа к памяти данных
    // -------------------------------------------------------
    covergroup cg_data_mem;
        cp_addr: coverpoint sampled_mem_addr {
            bins low_range   = {[8'h00:8'h0F]};
            bins mid_range   = {[8'h10:8'h7F]};
            bins high_range  = {[8'h80:8'hFE]};
            bins boundary    = {8'hFF};
        }

        cp_data: coverpoint sampled_mem_data {
            bins zero       = {8'h00};
            bins lo_vals    = {[8'h01:8'h0F]};
            bins mid_vals   = {[8'h10:8'h7F]};
            bins hi_vals    = {[8'h80:8'hFE]};
            bins max_val    = {8'hFF};
        }

        cp_direction: coverpoint sampled_is_read {
            bins read  = {1};
            bins write = {0};
        }

        // Кросс-покрытие: адрес × направление
        cx_addr_dir: cross cp_addr, cp_direction;
    endgroup

    // -------------------------------------------------------
    // 4. Кросс-покрытие: ISA × конфигурация
    // -------------------------------------------------------
    covergroup cg_cross;
        cp_opcode: coverpoint sampled_opcode {
            bins arithmetic = {4'h3, 4'h4, 4'h5, 4'h6};  // ADD, SUB, MUL, DIV
            bins memory     = {4'h7, 4'h8};                // LDR, STR
            bins control    = {4'h1, 4'h2};                // BR, CMP
            bins other      = {4'h0, 4'h9, 4'hF};         // NOP, CONST, RET
        }

        cp_threads: coverpoint sampled_thread_count {
            bins low  = {[1:4]};
            bins high = {[5:$]};
        }

        cx_opcode_threads: cross cp_opcode, cp_threads;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        host_export     = new("host_export", this);
        data_mem_export = new("data_mem_export", this);
        prog_mem_export = new("prog_mem_export", this);

        cg_kernel_config = new();
        cg_isa           = new();
        cg_data_mem      = new();
        cg_cross         = new();

        kernel_count  = 0;
        kernel_active = 0;
    endfunction

    // -------------------------------------------------------
    // Host control → kernel config coverage
    // -------------------------------------------------------
    virtual function void write_host(host_ctrl_item t);
        if (t.is_write) begin
            sampled_thread_count = t.data;
            cg_kernel_config.sample();
            `uvm_info("COV", $sformatf("Sampled thread_count=%0d, kernel_cfg_cov=%.1f%%",
                sampled_thread_count, cg_kernel_config.get_coverage()), UVM_HIGH)
        end else begin
            kernel_count++;
            kernel_active = 1;
        end
    endfunction

    // -------------------------------------------------------
    // Program memory preload → ISA coverage
    // -------------------------------------------------------
    virtual function void write_prog_mem(memory_item t);
        if (t.op == memory_item::WRITE) begin
            sampled_opcode = t.data[15:12];
            cg_isa.sample();
            // Кросс-покрытие (опкод × thread_count) семплируется
            // только если thread_count уже известен
            if (sampled_thread_count > 0)
                cg_cross.sample();
        end
    endfunction

    // -------------------------------------------------------
    // Data memory transactions → memory access coverage
    // -------------------------------------------------------
    virtual function void write_data_mem(memory_item t);
        sampled_mem_addr = t.addr;
        sampled_mem_data = t.data[7:0];
        sampled_is_read  = (t.op == memory_item::READ);
        sampled_is_write = (t.op == memory_item::WRITE);
        cg_data_mem.sample();
    endfunction

    // -------------------------------------------------------
    // Reset state (для multi-iteration тестов)
    // -------------------------------------------------------
    function void reset();
        kernel_active = 0;
    endfunction

    // -------------------------------------------------------
    // Итоговый отчёт о покрытии
    // -------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        real total_cov;
        super.report_phase(phase);

        total_cov = (cg_kernel_config.get_coverage() +
                     cg_isa.get_coverage() +
                     cg_data_mem.get_coverage() +
                     cg_cross.get_coverage()) / 4.0;

        `uvm_info("COV", "============================================", UVM_LOW)
        `uvm_info("COV", "        COVERAGE SUMMARY", UVM_LOW)
        `uvm_info("COV", "============================================", UVM_LOW)
        `uvm_info("COV", $sformatf("  Kernel config  : %6.1f%%", cg_kernel_config.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  ISA opcodes    : %6.1f%%", cg_isa.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Data memory    : %6.1f%%", cg_data_mem.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Cross coverage : %6.1f%%", cg_cross.get_coverage()), UVM_LOW)
        `uvm_info("COV", "--------------------------------------------", UVM_LOW)
        `uvm_info("COV", $sformatf("  AVERAGE        : %6.1f%%", total_cov), UVM_LOW)
        `uvm_info("COV", $sformatf("  Kernels run    : %0d", kernel_count), UVM_LOW)
        `uvm_info("COV", "============================================", UVM_LOW)
    endfunction
endclass
