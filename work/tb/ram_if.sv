`timescale 1ns / 1ps

interface ram_if #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (input logic clk);
  logic wrA, wrB;
  logic [ADDR_WIDTH-1:0] addrA, addrB;
  logic [DATA_WIDTH-1:0] dataA_in, dataB_in;
  logic [DATA_WIDTH-1:0] dataA_out, dataB_out;

endinterface
