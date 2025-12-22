`timescale 1ns / 1ps
module dp_ram_tb();

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 4;
localparam DEPTH      = 1 << ADDR_WIDTH;

logic clk;
logic rst;

logic wrA;
logic [ADDR_WIDTH-1:0] addrA;
logic [DATA_WIDTH-1:0] dataA_in;
logic [DATA_WIDTH-1:0] dataA_out;

logic wrB;
logic [ADDR_WIDTH-1:0] addrB;
logic [DATA_WIDTH-1:0] dataB_in;
logic [DATA_WIDTH-1:0] dataB_out;

dp_ram #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH)
) dut (.*);

logic [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

initial begin
  clk = 0;
  forever #5 clk = ~clk;  
end

initial begin
    rst = 1;
    #10;
    rst = 0;
end

task automatic check(
  input string port,
  input logic [ADDR_WIDTH-1:0] addr,
  input logic[DATA_WIDTH-1:0] exp,
  input logic[DATA_WIDTH-1:0] got
);
  if (got === exp) $display("Port %s addr=0x%0h: exp=%h, got=%h", port, addr, exp, got);
endtask


task automatic do_write(
  input logic        portA_en,
  input logic [3:0]  portA_addr,
  input logic [7:0]  portA_data,
  input logic        portB_en = 0,
  input logic [3:0]  portB_addr = 0,
  input logic [7:0]  portB_data = 0
);
  @(posedge clk);
    wrA      <= portA_en;
    addrA    <= portA_addr;
    dataA_in <= portA_data;
    wrB      <= portB_en;
    addrB    <= portB_addr;
    dataB_in <= portB_data;
  @(posedge clk);
    wrA <= 0;
    wrB <= 0;
endtask

task automatic do_read(
  input string        port,
  input logic [3:0]   raddr,
  input logic [7:0]   expected
);
  @(posedge clk);
    if (port == "A") begin
      wrA   = 0;
      addrA = raddr;
    end else begin
      wrB   = 0;
      addrB = raddr;
    end
  @(posedge clk);
    check(port, raddr, expected, (port == "A") ? dataA_out : dataB_out);
endtask


initial begin
  // 1) Initialize reference model and DUT RAM to zero
  for (int i = 0; i < DEPTH; i++) begin
    do_write(1, i, 0);       // write zero on Port A
    ref_mem[i] = 0;
  end

  // 2) Simple Port A write/read
  do_write(1, 4'h1, 8'hA1);
  ref_mem[4'h1] = 8'hA1;
  do_read("A", 4'h1, ref_mem[4'h1]);

  // 3) Simple Port B write/read
  do_write(0, 0, 0, 1, 4'h2, 8'hB2);
  ref_mem[4'h2] = 8'hB2;
  do_read("B", 4'h2, ref_mem[4'h2]);

  // 4) Cross-port read (A writes, B reads next cycle)
  do_write(1, 4'h3, 8'hC3);
  ref_mem[4'h3] = 8'hC3;
//  do_read("A", 4'h3, ref_mem[4'h3]);
  do_read("B", 4'h3, ref_mem[4'h3]);
 
  // 5) Simultaneous writes to different addresses
  do_write(1, 4'h4, 8'hD4, 1, 4'h5, 8'hE5);
  ref_mem[4'h4] = 8'hD4;
  ref_mem[4'h5] = 8'hE5;
  do_read("A", 4'h4, ref_mem[4'h4]);
  do_read("B", 4'h5, ref_mem[4'h5]);

  // 6) Conflict write to same address: B should win
  do_write(1, 4'h6, 8'hF6, 1, 4'h6, 8'h17);
  // port outputs will be 'x on collision; skip checking outputs
  ref_mem[4'h6] = 8'h17;  // B wins
   // give one more cycle to settle
   // @ cycle N, both writes write, mem hasnt changed yet, read reads x
   // @ cycle N+1, writes deasserts, NBAs commit the data, read reads the data
  @(posedge clk);
  check("A", 4'h6, dataA_out, 'x);
  check("B", 4'h6, dataB_out, 'x);
  do_read("A", 4'h6, ref_mem[4'h6]);
  do_read("B", 4'h6, ref_mem[4'h6]);

  $display(">> ALL TESTS COMPLETE <<");
  $finish;
end

endmodule
