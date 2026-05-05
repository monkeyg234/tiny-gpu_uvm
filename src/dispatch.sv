`default_nettype none
`timescale 1ns/1ns

module dispatch #(
    parameter NUM_CORES = 2,
    parameter THREADS_PER_BLOCK = 4
) (
    input wire clk,
    input wire reset,
    input wire start,

    input wire [7:0] thread_count,

    input wire [NUM_CORES-1:0] core_done,
    output reg [NUM_CORES-1:0] core_start,
    output reg [NUM_CORES-1:0] core_reset,
    output reg [7:0] core_block_id [NUM_CORES-1:0],
    output reg [$clog2(THREADS_PER_BLOCK):0] core_thread_count [NUM_CORES-1:0],

    output reg done
);
    reg [7:0] blocks_dispatched;
    reg [7:0] blocks_done;
    reg [7:0] total_blocks_reg;
    reg start_execution;

    // We use a temporary variable for the combinational logic of dispatching multiple blocks in one cycle
    int next_blocks_dispatched;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done              <= 0;
            start_execution   <= 0;
            blocks_dispatched <= 0;
            blocks_done       <= 0;
            total_blocks_reg  <= 0;
            for (int i = 0; i < NUM_CORES; i++) begin
                core_reset[i] <= 1;
                core_start[i] <= 0;
                core_block_id[i] <= 0;
                core_thread_count[i] <= THREADS_PER_BLOCK;
            end
        end else if (start) begin
            if (!start_execution) begin
                start_execution   <= 1;
                done              <= 0;
                blocks_dispatched <= 0;
                blocks_done       <= 0;
                total_blocks_reg  <= (thread_count + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
                for (int i = 0; i < NUM_CORES; i++) begin
                    core_reset[i] <= 1;
                    core_start[i] <= 0;
                end
            end else begin
                if (total_blocks_reg > 0 && blocks_done == total_blocks_reg) begin
                    done <= 1;
                end

                next_blocks_dispatched = blocks_dispatched;
                for (int i = 0; i < NUM_CORES; i++) begin
                    if (core_reset[i]) begin
                        if (next_blocks_dispatched < total_blocks_reg) begin
                            core_reset[i] <= 0;
                            core_start[i] <= 1;
                            core_block_id[i] <= next_blocks_dispatched[7:0];
                            core_thread_count[i] <= (next_blocks_dispatched[7:0] == total_blocks_reg - 1)
                                ? (thread_count - (next_blocks_dispatched[7:0] * THREADS_PER_BLOCK))
                                : THREADS_PER_BLOCK;
                            next_blocks_dispatched = next_blocks_dispatched + 1;
                        end
                    end

                    if (core_start[i] && core_done[i]) begin
                        core_reset[i] <= 1;
                        core_start[i] <= 0;
                        blocks_done   <= blocks_done + 1;
                    end
                end
                blocks_dispatched <= next_blocks_dispatched[7:0];
            end
        end else begin
            start_execution <= 0;
            // done stays high until next start/reset
        end
    end
endmodule