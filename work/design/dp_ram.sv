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

logic [DATA_WIDTH-1:0] mem [0:1<<ADDR_WIDTH-1];


always_ff @(posedge clk) begin
  if(rst) begin
    dataA_out <= '0;
    dataB_out <= '0;
  end else begin
      if (wrB) begin// B mem write
        mem[addrB] <= dataB_in;
      end
      if (wrA && !(wrB && (addrA == addrB))) begin // A mem write unless B also writes at the same addr
        mem[addrA] <= dataA_in;
      end
      
      // A output
      // if B writes same address that A reads, A should see B's new data
      if (wrA) begin // A write: unless B overwrote same addr, A sees its write
        dataA_out <= (wrB && (addrA == addrB)) ? dataB_in : dataA_in;
      end else begin// A read: if B wrote same address this cycle, show B's data
        dataA_out <= (wrB && (addrA == addrB)) ? dataB_in : mem[addrA];
      end

      // B output
      if (wrB) begin
        dataB_out <= dataB_in;
      end else begin 
        dataB_out <= mem[addrB];
      end
  end
end

endmodule
