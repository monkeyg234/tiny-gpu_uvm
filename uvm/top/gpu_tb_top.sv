`timescale 1ns / 1ns

module gpu_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;
    import gpu_test_pkg::*;

    logic clk;
    logic reset;

    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    initial begin
        reset = 1;
        #20ns reset = 0;
    end

    host_ctrl_if h_if(clk, reset);
    memory_if #(8, 16, 1) p_if(clk, reset);
    memory_if #(8, 8, 4)  d_if(clk, reset);

    // Flat buses match sv2v Verilog DUT (packed channel buses). Unpacked interface arrays
    // are mapped explicitly so strict simulators (e.g. Vivado xsim) accept the connections.
    localparam int PM_CH = 1;
    localparam int PM_AB = 8;
    localparam int PM_DB = 16;
    localparam int DM_CH = 4;
    localparam int DM_AB = 8;
    localparam int DM_DB = 8;

    wire [PM_CH-1:0]                 w_pm_rvalid;
    wire [PM_CH*PM_AB-1:0]         w_pm_raddr;
    wire [PM_CH-1:0]               w_pm_rready;
    wire [PM_CH*PM_DB-1:0]         w_pm_rdata;
    wire [DM_CH-1:0]               w_dm_rvalid;
    wire [DM_CH*DM_AB-1:0]         w_dm_raddr;
    wire [DM_CH-1:0]               w_dm_rready;
    wire [DM_CH*DM_DB-1:0]         w_dm_rdata;
    wire [DM_CH-1:0]               w_dm_wvalid;
    wire [DM_CH*DM_AB-1:0]         w_dm_waddr;
    wire [DM_CH*DM_DB-1:0]         w_dm_wdata;
    wire [DM_CH-1:0]               w_dm_wready;

    gpu #(
        .DATA_MEM_ADDR_BITS(8),
        .DATA_MEM_DATA_BITS(8),
        .DATA_MEM_NUM_CHANNELS(4),
        .PROGRAM_MEM_ADDR_BITS(8),
        .PROGRAM_MEM_DATA_BITS(16),
        .PROGRAM_MEM_NUM_CHANNELS(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(h_if.start),
        .done(h_if.done),
        .device_control_write_enable(h_if.device_control_write_enable),
        .device_control_data(h_if.device_control_data),

        .program_mem_read_valid(w_pm_rvalid),
        .program_mem_read_address(w_pm_raddr),
        .program_mem_read_ready(w_pm_rready),
        .program_mem_read_data(w_pm_rdata),

        .data_mem_read_valid(w_dm_rvalid),
        .data_mem_read_address(w_dm_raddr),
        .data_mem_read_ready(w_dm_rready),
        .data_mem_read_data(w_dm_rdata),
        .data_mem_write_valid(w_dm_wvalid),
        .data_mem_write_address(w_dm_waddr),
        .data_mem_write_data(w_dm_wdata),
        .data_mem_write_ready(w_dm_wready)
    );

    assign p_if.read_valid = w_pm_rvalid;
    assign p_if.read_address[0] = w_pm_raddr;
    assign w_pm_rready = p_if.read_ready;
    assign w_pm_rdata = p_if.read_data[0];

    assign d_if.read_valid = w_dm_rvalid;
    assign d_if.write_valid = w_dm_wvalid;
    assign w_dm_rready = d_if.read_ready;
    assign w_dm_wready = d_if.write_ready;

    genvar gi;
    generate
        for (gi = 0; gi < DM_CH; gi++) begin : g_dm_map
            assign d_if.read_address[gi]  = w_dm_raddr[gi*DM_AB +: DM_AB];
            assign d_if.write_address[gi] = w_dm_waddr[gi*DM_AB +: DM_AB];
            assign d_if.write_data[gi]    = w_dm_wdata[gi*DM_DB +: DM_DB];
            assign w_dm_rdata[gi*DM_DB +: DM_DB] = d_if.read_data[gi];
        end
    endgenerate

    initial begin
        uvm_config_db#(virtual host_ctrl_if)::set(null, "*", "h_vif", h_if);
        uvm_config_db#(virtual memory_if#(8,16,1))::set(null, "*", "p_vif", p_if);
        uvm_config_db#(virtual memory_if#(8,8,4))::set(null, "*", "d_vif", d_if);
        
        run_test();
    end
endmodule
