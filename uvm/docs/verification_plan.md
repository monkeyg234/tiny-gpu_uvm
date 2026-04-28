# Verification Plan — tiny-gpu

## 1. Область верификации

DUT: `gpu` (top-level) — минимальный GPGPU: DCR, Dispatcher, 2× Core (Scheduler, Fetcher, Decoder, 4× ALU/LSU/PC/Registers), Memory Controllers.

---

## 2. Список проверяемых характеристик

### A. RESET & ИНИЦИАЛИЗАЦИЯ

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| A.1 | Global Reset | При `reset=1`: `done=0`, все `core_state=IDLE`, `current_pc=0`, регистры обнулены, memory controller в IDLE, DCR=0 | P0 |
| A.2 | Reset во время исполнения | Подать reset в середине выполнения ядра — GPU должен корректно остановиться и вернуться в начальное состояние | P1 |
| A.3 | Запрет раннего старта | Без записи thread_count в DCR и подачи `start` GPU не начинает работу — `done` остаётся 0, core_state=IDLE | P0 |
| A.4 | Повторный reset-start | После завершения ядра подать reset, заново загрузить программу/данные и запустить — повторное исполнение корректно | P1 |

### B. DEVICE CONTROL REGISTER (dcr.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| B.1 | Запись thread_count | `device_control_write_enable=1` → `device_control_data` записывается, `thread_count` обновляется на следующем такте | P0 |
| B.2 | Удержание значения | Без `write_enable` значение `thread_count` не меняется | P0 |
| B.3 | Перезапись | Последовательная запись нескольких значений — сохраняется последнее | P1 |
| B.4 | Reset DCR | При reset DCR обнуляется | P0 |
| B.5 | Граничные значения | thread_count=0, 1, 4, 8, 255 — корректное поведение dispatch | P1 |

### C. DISPATCHER (dispatch.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| C.1 | Расчёт total_blocks | `total_blocks = ceil(thread_count / THREADS_PER_BLOCK)`. Проверить для thread_count=1,4,5,8,9,255 | P0 |
| C.2 | Начальная раздача блоков | При `start=1` dispatcher раздаёт по одному блоку каждому из 2 ядер с правильными `block_id` и `thread_count` | P0 |
| C.3 | Последний блок — неполный | Если thread_count не кратен THREADS_PER_BLOCK, последний блок получает `thread_count % THREADS_PER_BLOCK` потоков | P0 |
| C.4 | Переиспользование ядер | После `core_done[i]=1` ядро получает reset, затем новый блок (если есть нераздаченные) | P0 |
| C.5 | Сигнал done | `done=1` только когда `blocks_done == total_blocks` | P0 |
| C.6 | Один блок | thread_count ≤ THREADS_PER_BLOCK → только 1 блок, 1 ядро работает | P1 |
| C.7 | Много блоков | thread_count >> NUM_CORES × THREADS_PER_BLOCK → ядра многократно переиспользуются | P1 |
| C.8 | start_execution guard | Повторный posedge start не перезапускает dispatch | P2 |

### D. MEMORY CONTROLLER (controller.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| D.1 | Single read request | Один consumer делает read_valid → контроллер передаёт запрос в память → ответ возвращается consumer | P0 |
| D.2 | Single write request | Аналогично для write | P0 |
| D.3 | Арбитраж: приоритет | При одновременных запросах от нескольких consumers → first-found (по индексу) обслуживается первым | P0 |
| D.4 | Арбитраж: не дублировать | Один запрос не подхватывается двумя каналами (channel_serving_consumer) | P0 |
| D.5 | Многоканальность | NUM_CHANNELS каналов обрабатывают запросы параллельно | P1 |
| D.6 | FSM переходы | IDLE→READ_WAITING→READ_RELAYING→IDLE, IDLE→WRITE_WAITING→WRITE_RELAYING→IDLE | P0 |
| D.7 | Throttling | Больше consumers чем каналов — запросы ставятся в очередь, не теряются | P1 |
| D.8 | Back-pressure памяти | Память не отвечает сразу (mem_read_ready задерживается) — контроллер ждёт | P1 |
| D.9 | Read-only controller | Program memory controller (WRITE_ENABLE=0) — write запросы не проходят | P1 |
| D.10 | Reset controller | При reset все состояния обнуляются, запросы в полёте отменяются | P0 |

### E. SCHEDULER / CORE FSM (scheduler.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| E.1 | FSM последовательность | IDLE→FETCH→DECODE→REQUEST→WAIT→EXECUTE→UPDATE→FETCH (цикл) | P0 |
| E.2 | IDLE→FETCH по start | Переход из IDLE только при start=1 | P0 |
| E.3 | FETCH ожидание | Остаётся в FETCH пока fetcher_state ≠ FETCHED (3'b010) | P0 |
| E.4 | WAIT завершение | Выходит из WAIT только когда все LSU не в состоянии REQUESTING/WAITING | P0 |
| E.5 | RET → DONE | При decoded_ret=1 в фазе UPDATE → done=1, core_state=DONE | P0 |
| E.6 | PC обновление | В UPDATE: current_pc ← next_pc[THREADS_PER_BLOCK-1] | P0 |
| E.7 | DONE — стабильность | После перехода в DONE состояние не меняется до reset | P1 |

### F. FETCHER (fetcher.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| F.1 | Fetch по PC | При core_state=FETCH → mem_read_valid=1, mem_read_address=current_pc | P0 |
| F.2 | Ожидание ответа | Ждёт mem_read_ready, сохраняет instruction = mem_read_data | P0 |
| F.3 | FSM переходы | IDLE→FETCHING→FETCHED→IDLE | P0 |
| F.4 | Задержка памяти | Память отвечает через N тактов — fetcher корректно ожидает | P1 |

### G. DECODER (decoder.sv) — полный ISA

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| G.1 | NOP (0x0) | Все control signals = 0 | P0 |
| G.2 | ADD (0x3) | reg_write_enable=1, reg_input_mux=00, alu_arithmetic_mux=00 | P0 |
| G.3 | SUB (0x4) | reg_write_enable=1, reg_input_mux=00, alu_arithmetic_mux=01 | P0 |
| G.4 | MUL (0x5) | reg_write_enable=1, reg_input_mux=00, alu_arithmetic_mux=10 | P0 |
| G.5 | DIV (0x6) | reg_write_enable=1, reg_input_mux=00, alu_arithmetic_mux=11 | P0 |
| G.6 | LDR (0x7) | reg_write_enable=1, reg_input_mux=01, mem_read_enable=1 | P0 |
| G.7 | STR (0x8) | mem_write_enable=1 | P0 |
| G.8 | CONST (0x9) | reg_write_enable=1, reg_input_mux=10 | P0 |
| G.9 | CMP (0x2) | alu_output_mux=1, nzp_write_enable=1 | P0 |
| G.10 | BRnzp (0x1) | pc_mux=1, decoded_nzp из instruction[11:9] | P0 |
| G.11 | RET (0xF) | decoded_ret=1 | P0 |
| G.12 | Поля инструкции | rd=instr[11:8], rs=instr[7:4], rt=instr[3:0], immediate=instr[7:0] | P0 |
| G.13 | Неиспользуемые opcodes | Opcodes 0xA-0xE — поведение по умолчанию (signals=0) | P2 |

### H. ALU (alu.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| H.1 | ADD корректность | alu_out = rs + rt для значений (0+0, 1+1, 127+128, 255+1 overflow) | P0 |
| H.2 | SUB корректность | alu_out = rs - rt, включая underflow | P0 |
| H.3 | MUL корректность | alu_out = rs × rt (8-bit truncated) | P0 |
| H.4 | DIV корректность | alu_out = rs / rt | P0 |
| H.5 | CMP: rs > rt | alu_out = 3'b100 (positive) | P0 |
| H.6 | CMP: rs == rt | alu_out = 3'b010 (zero) | P0 |
| H.7 | CMP: rs < rt | alu_out = 3'b001 (negative) | P0 |
| H.8 | Enable=0 | Отключенный ALU не обновляет alu_out | P1 |
| H.9 | Timing | ALU считает только при core_state=EXECUTE (3'b101) | P0 |
| H.10 | DIV на ноль | Поведение при rt=0 — зафиксировать фактическое | P2 |

### I. LSU (lsu.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| I.1 | LDR flow | IDLE→REQUESTING→WAITING→DONE: address=rs, данные в lsu_out | P0 |
| I.2 | STR flow | IDLE→REQUESTING→WAITING→DONE: address=rs, data=rt | P0 |
| I.3 | REQUEST phase | LSU начинает только при core_state=REQUEST | P0 |
| I.4 | UPDATE reset | LSU возвращается в IDLE при core_state=UPDATE | P0 |
| I.5 | Задержка памяти | Разные задержки mem_ready — LSU корректно ждёт | P1 |
| I.6 | Enable=0 | Отключенный LSU не генерирует запросы | P1 |

### J. PROGRAM COUNTER (pc.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| J.1 | Инкремент | По умолчанию next_pc = current_pc + 1 | P0 |
| J.2 | Branch taken | pc_mux=1, (nzp & decoded_nzp)≠0 → next_pc = immediate | P0 |
| J.3 | Branch not taken | pc_mux=1, (nzp & decoded_nzp)==0 → next_pc = current_pc + 1 | P0 |
| J.4 | NZP update | В UPDATE при nzp_write_enable=1 → nzp ← alu_out[2:0] | P0 |
| J.5 | NZP retention | Без nzp_write_enable NZP не меняется | P0 |
| J.6 | All branch conds | BRn, BRz, BRp, BRnz, BRnp, BRzp, BRnzp | P1 |

### K. REGISTER FILE (registers.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| K.1 | R13 = %blockIdx | R13 = block_id (read-only) | P0 |
| K.2 | R14 = %blockDim | R14 = THREADS_PER_BLOCK (const) | P0 |
| K.3 | R15 = %threadIdx | R15 = THREAD_ID (уникален) | P0 |
| K.4 | Write R0-R12 | reg_write_enable=1, rd<13 → обновление | P0 |
| K.5 | Protect R13-R15 | Запись с rd≥13 игнорируется | P0 |
| K.6 | Source: ALU | reg_input_mux=00 → rd ← alu_out | P0 |
| K.7 | Source: Memory | reg_input_mux=01 → rd ← lsu_out | P0 |
| K.8 | Source: Constant | reg_input_mux=10 → rd ← immediate | P0 |
| K.9 | Reset registers | R0-R12=0, R14=THREADS_PER_BLOCK, R15=THREAD_ID | P0 |

### L. СИСТЕМНАЯ ИНТЕГРАЦИЯ (gpu.sv)

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| L.1 | Полный цикл | DCR write → start → выполнение → done=1 | P0 |
| L.2 | MatAdd kernel | 8 потоков, C[i]=A[i]+B[i], проверка результата | P0 |
| L.3 | MatMul kernel | 4 потока, 2×2 матрицы с циклами BRnzp | P0 |
| L.4 | LSU↔Controller | 8 LSU через 4 канала — корректный арбитраж | P0 |
| L.5 | Fetcher↔Controller | 2 fetcher через 1 канал — арбитраж | P0 |
| L.6 | Два ядра | Оба ядра работают параллельно | P1 |
| L.7 | Один поток | thread_count=1 → 1 блок, 1 ядро | P1 |
| L.8 | Нечётное кол-во | thread_count=5 → блок(4) + блок(1) | P1 |

### M. ТАЙМИНГИ

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| M.1 | Латентность инструкции | Тактов от FETCH до UPDATE для каждого типа | P1 |
| M.2 | Латентность LDR/STR | Зависит от задержки памяти (1, 5, 10 тактов) | P1 |
| M.3 | Done timing | done=1 после blocks_done==total_blocks | P1 |
| M.4 | Pipeline stages | DECODE, REQUEST, EXECUTE, UPDATE — каждый ровно 1 такт | P1 |

### N. CORNER CASES

| # | Feature | Описание | Приоритет |
|---|---------|----------|-----------|
| N.1 | thread_count=0 | Проверить поведение dispatch | P1 |
| N.2 | DIV by zero | Зафиксировать поведение | P2 |
| N.3 | Overflow/Underflow | ADD 200+200, SUB 0-1, MUL 20×20 | P1 |
| N.4 | BRnzp без CMP | NZP=000 → branch not taken | P1 |
| N.5 | Программа без RET | Ядро не завершается — таймаут | P2 |
| N.6 | Start без reset | После done без reset — поведение | P2 |

---

## 3. Тестовые сценарии

### Unit-level

| TC | Target | Описание |
|----|--------|----------|
| TC-U1 | DCR | Write/read/reset |
| TC-U2 | ALU | Каждая операция × граничные значения |
| TC-U3 | Decoder | Каждый opcode → все control signals |
| TC-U4 | PC | Инкремент + branch ×7 NZP-комбинаций |
| TC-U5 | Registers | Write R0-R12, protect R13-R15 |
| TC-U6 | Fetcher | FSM с разными задержками памяти |
| TC-U7 | LSU | LDR/STR FSM с задержками |
| TC-U8 | Controller | N consumers, M channels, арбитраж |
| TC-U9 | Scheduler | FSM для каждого типа инструкции |
| TC-U10 | Dispatcher | Разные thread_count |

### Integration

| TC | Target | Описание |
|----|--------|----------|
| TC-I1 | Core | Single-instruction kernels каждого типа |
| TC-I2 | Core+Mem | LDR → ALU → STR цепочка |
| TC-I3 | Core loop | CMP+BRnzp цикл |
| TC-I4 | Multi-core | 2 ядра параллельно |
| TC-I5 | Contention | 8 LSU через 4 канала |

### System / Kernel

| TC | Target | Описание |
|----|--------|----------|
| TC-S1 | MatAdd | Полный тест, проверка C=A+B |
| TC-S2 | MatMul | Полный тест, проверка C=A×B |
| TC-S3 | Random MatAdd | Рандомные данные + reference model |
| TC-S4 | Stress | thread_count=255 |

---

## 4. Coverage Plan

### Functional Coverage

| Group | Coverpoints |
|-------|-------------|
| ISA | Каждый из 11 opcodes выполнен |
| ALU ops | Каждая операция × граничные (0,1,127,128,255) |
| Branch | Taken/not taken × 7 NZP-комбинаций |
| Registers | Write/read R0-R12, read R13-R15 |
| Core FSM | Все 8 состояний, все переходы |
| Fetcher FSM | 3 состояния, 3 перехода |
| LSU FSM | 4 состояния × LDR/STR |
| Controller FSM | 5 состояний × read/write |
| Dispatcher | blocks 1..64, threads per core 1..4 |

### Code Coverage

| Метрика | Цель |
|---------|------|
| Line | ≥ 95% |
| Branch | ≥ 90% |
| Toggle | ≥ 85% |
| FSM | 100% |

---

## 5. Фазы выполнения

| Фаза | Scope | Coverage |
|------|-------|----------|
| **1** | P0: Reset, DCR, Decoder, ALU, Registers, MatAdd | ~60% |
| **2** | P1: Dispatcher, Controller, LSU timing, MatMul, Corner cases | ~85% |
| **3** | P2: Stress, random, unused opcodes, coverage closure | ≥95% |
