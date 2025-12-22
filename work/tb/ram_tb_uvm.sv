`timescale 1ns / 1ps
`include "ram_pkg.sv"
`include "ram_if.sv"

module ram_tb;
  import uvm_pkg::*;
  import ram_pkg::*;
  
 
  
  logic clk, rst;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst = 1;
    #10;
    rst = 0;
  end
  
  ram_if ram_if(clk);
  dp_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
    .clk (clk),
    .rst (rst),          
      
    .wrA       (ram_if.wrA),
    .addrA     (ram_if.addrA),
    .dataA_in  (ram_if.dataA_in),
    .dataA_out (ram_if.dataA_out),

    .wrB       (ram_if.wrB),
    .addrB     (ram_if.addrB),
    .dataB_in  (ram_if.dataB_in),
    .dataB_out (ram_if.dataB_out)
  );
  
  initial begin
    $timeformat(-9, 0, "ns");
    uvm_config_db#(virtual ram_if)::set(null, "", "vif", ram_if);
    run_test("ram_test");
  end
  

endmodule
