`timescale 1ns / 1ps

module dp_ram #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 4)(
  input logic clk, rst,

  input logic wrA,
  input logic [ADDR_WIDTH-1:0] addrA,
  input logic [DATA_WIDTH-1:0] dataA_in,
  output logic [DATA_WIDTH-1:0] dataA_out,

  input logic wrB,
  input logic [ADDR_WIDTH-1:0] addrB,
  input logic [DATA_WIDTH-1:0] dataB_in,
  output logic [DATA_WIDTH-1:0] dataB_out
);

logic [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];


always_ff @(posedge clk) begin
  if(rst) begin
    dataA_out <= '0;
    dataB_out <= '0;
  end else begin
      if (wrA && wrB && (addrA == addrB)) begin
        mem[addrA] <= dataA_in;
        mem[addrB] <= dataB_in;
        dataA_out  <= 'x;
        dataB_out  <= 'x;
      end else begin
        if (wrA)
          mem[addrA] <= dataA_in;
        dataA_out  <= wrA ? dataA_in : mem[addrA];
        if (wrB)
          mem[addrB] <= dataB_in;
        dataB_out  <= wrB ? dataB_in : mem[addrB];
      end
    end
  end

endmodule
