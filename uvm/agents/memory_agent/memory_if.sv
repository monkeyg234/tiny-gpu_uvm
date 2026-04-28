interface memory_if #(
    parameter ADDR_BITS = 8,
    parameter DATA_BITS = 8,
    parameter NUM_CHANNELS = 1
)(input logic clk, input logic reset);

    logic [NUM_CHANNELS-1:0] read_valid;
    logic [NUM_CHANNELS*ADDR_BITS-1:0] read_address;
    logic [NUM_CHANNELS-1:0] read_ready;
    logic [NUM_CHANNELS*DATA_BITS-1:0] read_data;

    logic [NUM_CHANNELS-1:0] write_valid;
    logic [NUM_CHANNELS*ADDR_BITS-1:0] write_address;
    logic [NUM_CHANNELS*DATA_BITS-1:0] write_data;
    logic [NUM_CHANNELS-1:0] write_ready;

    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        output read_ready;
        output read_data;
        output write_ready;
        input  read_valid;
        input  read_address;
        input  write_valid;
        input  write_address;
        input  write_data;
    endclocking

    modport mp (clocking cb, input clk, input reset);
endinterface
