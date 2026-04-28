`timescale 1ns / 1ns

module gpu_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import clk_pkg::*;
    import rst_pkg::*;
    import done_pkg::*;
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;
    import gpu_test_pkg::*;

    // -------------------------------------------------------
    // Clock & Reset — driven by UVM agents (not hardcoded)
    // -------------------------------------------------------
    clk_agent_if  clk_if();
    rst_agent_if  rst_if(clk_if.clk);

    wire clk   = clk_if.clk;
    wire reset = rst_if.reset;

    // -------------------------------------------------------
    // DUT Interfaces
    // -------------------------------------------------------
    host_ctrl_if h_if(clk, reset);
    memory_if #(8, 16, 1) p_if(clk, reset);
    memory_if #(8, 8, 4)  d_if(clk, reset);
    done_agent_if done_if(clk);

    // -------------------------------------------------------
    // GPU DUT — parametric memory width
    // -------------------------------------------------------
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

    // -------------------------------------------------------
    // Done signal → done_if
    // -------------------------------------------------------
    assign done_if.done = h_if.done;

    // -------------------------------------------------------
    // Program Memory wiring
    // -------------------------------------------------------
    assign p_if.read_valid = w_pm_rvalid;
    assign p_if.read_address = w_pm_raddr;
    assign w_pm_rready = p_if.read_ready;
    assign w_pm_rdata = p_if.read_data;

    // -------------------------------------------------------
    // Data Memory wiring
    // -------------------------------------------------------
    assign d_if.read_valid = w_dm_rvalid;
    assign d_if.read_address = w_dm_raddr;
    assign w_dm_rready = d_if.read_ready;
    assign w_dm_rdata = d_if.read_data;

    assign d_if.write_valid = w_dm_wvalid;
    assign d_if.write_address = w_dm_waddr;
    assign d_if.write_data = w_dm_wdata;
    assign w_dm_wready = d_if.write_ready;

    // -------------------------------------------------------
    // UVM config_db — pass interfaces to agents
    // -------------------------------------------------------
    initial begin
        uvm_config_db#(virtual clk_agent_if)::set(null, "*", "clk_vif", clk_if);
        uvm_config_db#(virtual rst_agent_if)::set(null, "*", "rst_vif", rst_if);
        uvm_config_db#(virtual done_agent_if)::set(null, "*", "done_vif", done_if);
        uvm_config_db#(virtual host_ctrl_if)::set(null, "*", "h_vif", h_if);
        uvm_config_db#(virtual memory_if#(8,16,1))::set(null, "*", "p_vif", p_if);
        uvm_config_db#(virtual memory_if#(8,8,4))::set(null, "*", "d_vif", d_if);
        
        run_test();
    end
endmodule
