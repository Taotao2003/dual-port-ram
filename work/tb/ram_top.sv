`timescale 1ns / 1ps


module ram_tb;
  import uvm_pkg::*;
  import ram_pkg::*;

  `include "ram_env.sv"

  logic clk, rst;
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
  initial begin
    rst = 1;
    #10;
    rst = 0;
  end
  
  ram_if ram_if(clk);
  assign ram_if.rst = rst;
  
  dp_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
    .clk (clk),
    .rst (rst),          
      
    .wr_a       (ram_if.wr_a),
    .addr_a    (ram_if.addr_a),
    .data_a_in  (ram_if.data_a_in),
    .data_a_out (ram_if.data_a_out),

    .wr_b       (ram_if.wr_b),
    .addr_b     (ram_if.addr_b),
    .data_b_in  (ram_if.data_b_in),
    .data_b_out (ram_if.data_b_out)
  );
  
  initial begin
    $timeformat(-9, 0, "ns");
    uvm_config_db#(virtual ram_if)::set(null, "", "vif", ram_if);
    `uvm_info("TOP", "Starting UVM Test", UVM_LOW)
    run_test();
    `uvm_info("TOP", "UVM Test Finished", UVM_LOW)
  end
  

endmodule
