// gpu_matadd_seq.sv — Последовательность для теста сложения матриц.
// Наследует утилиты загрузки/запуска из gpu_base_vseq.
class gpu_matadd_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_matadd_seq)

    rand int num_threads;

    constraint c_threads {
        soft num_threads == 8;  // По умолчанию 8 потоков для 2×2+2×2
    }

    function new(string name = "gpu_matadd_seq");
        super.new(name);
    endfunction

    virtual task body();
        // MatAdd kernel program
        logic [15:0] prog[$] = '{
            16'h50DE, 16'h300F, 16'h9100, 16'h9208,
            16'h9310, 16'h3410, 16'h7440, 16'h3520,
            16'h7550, 16'h3645, 16'h3730, 16'h8076,
            16'hF000
        };

        // Данные: A[0..7] = {0,1,...,7}, B[8..15] = {0,1,...,7}
        logic [7:0] data_a[$];
        logic [7:0] data_b[$];
        for (int i = 0; i < 8; i++) begin
            data_a.push_back(i);
            data_b.push_back(i);
        end

        load_program(prog);
        load_data(0, data_a);
        load_data(8, data_b);
        launch_kernel(num_threads);
    endtask
endclass
