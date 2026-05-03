// gpu_stress_seq.sv — Стресс-последовательность со случайными данными.
// Наследует утилиты из gpu_base_vseq.
// Использует рандомизацию количества потоков и входных данных.
class gpu_stress_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_stress_seq)

    rand int num_threads;

    constraint c_threads {
        num_threads inside {[1:8]}; // От 1 до 8 потоков (включая неполные блоки)
    }

    function new(string name = "gpu_stress_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Та же программа MatAdd, но с рандомизированными данными
        logic [15:0] prog[$] = '{
            16'h50DE, 16'h300F, 16'h9100, 16'h9208,
            16'h9310, 16'h3410, 16'h7440, 16'h3520,
            16'h7550, 16'h3645, 16'h3730, 16'h8076,
            16'hF000
        };

        // Рандомизированные данные
        logic [7:0] data_a[$];
        logic [7:0] data_b[$];
        for (int i = 0; i < 8; i++) begin
            data_a.push_back(i + $urandom_range(0, 10));
            data_b.push_back(i + $urandom_range(0, 10));
        end

        load_program(prog);
        load_data(0, data_a);
        load_data(8, data_b);
        launch_kernel(num_threads);
    endtask
endclass
