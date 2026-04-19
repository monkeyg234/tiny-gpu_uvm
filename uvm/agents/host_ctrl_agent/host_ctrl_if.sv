interface host_ctrl_if (input logic clk, input logic reset);
    logic start;
    logic done;
    logic device_control_write_enable;
    logic [7:0] device_control_data;

    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        output start;
        output device_control_write_enable;
        output device_control_data;
        input  done;
    endclocking

    modport mp (clocking cb, input clk, input reset);
endinterface
