
package gpu_common_pkg;

    // -------------------------------------------------------
    // GPU Architecture Parameters
    // -------------------------------------------------------
    localparam int GPU_NUM_CORES         = 2;
    localparam int GPU_THREADS_PER_BLOCK = 4;

    localparam int GPU_DATA_ADDR_BITS    = 8;
    localparam int GPU_DATA_DATA_BITS    = 8;
    localparam int GPU_DATA_CHANNELS     = 4;

    localparam int GPU_PROG_ADDR_BITS    = 8;
    localparam int GPU_PROG_DATA_BITS    = 16;
    localparam int GPU_PROG_CHANNELS     = 1;

    // -------------------------------------------------------
    // ISA Opcodes
    // -------------------------------------------------------
    typedef enum logic [3:0] {
        OP_NOP   = 4'h0,
        OP_BRnzp = 4'h1,
        OP_CMP   = 4'h2,
        OP_ADD   = 4'h3,
        OP_SUB   = 4'h4,
        OP_MUL   = 4'h5,
        OP_DIV   = 4'h6,
        OP_LDR   = 4'h7,
        OP_STR   = 4'h8,
        OP_CONST = 4'h9,
        OP_RET   = 4'hF
    } opcode_e;

    // -------------------------------------------------------
    // Simulation Defaults
    // -------------------------------------------------------
    localparam int DEFAULT_WATCHDOG_TIMEOUT_NS = 2_000_000; // 2 ms

endpackage
