`timescale 1ns / 1ps

interface ram_if #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (input logic clk);

import uvm_pkg::*;
`include "uvm_macros.svh"

  logic wr_a, wr_b;
  logic [ADDR_WIDTH-1:0] addr_a, addr_b;
  logic [DATA_WIDTH-1:0] data_a_in, data_b_in;
  logic [DATA_WIDTH-1:0] data_a_out, data_b_out;


  // ASSERTIONS
  assert property (@(posedge clk) disable iff (rst)
    wr_a |-> (data_a_in != 8'h00)
  );
  assert property (@(posedge clk) disable iff (rst)
    wr_b |-> (data_b_in != 8'h00)
  );

  assert property (@(posedge clk) disable iff (rst)
    // port A write to out without collision
    (wr_a && !(wr_b && (addr_a == addr_b))) |-> (data_a_out == data_a_in)
  );
  
  assert property (@(posedge clk) disable iff (rst)
    // port B write to out without collision
    (wr_b |-> (data_b_out == data_b_in))
  );

  assert property (@(posedge clk) disable iff (rst)
    // on simultaneous writes to same addr, port A reads port B's data
    (wr_a && wr_b && addr_a == addr_b) |-> (data_a_out == data_b_in)
  );
  assert property (@(posedge clk) disable iff (rst)
    // on simultaneous writes to same addr, port B reads its own data
    (wr_a && wr_b && addr_a == addr_b) |-> (data_b_out == data_b_in )
  );

  assert property (@(posedge clk) disable iff (rst)
    // on simultaneous writes to same memory address, mem at addr A gets port B's data
    (wr_a && wr_b && (addr_a == addr_b)) |=> (mem[$past(addr_a)] == $past(data_b_in))
  );

  assert property (@(posedge clk) disable iff (rst)
    // on simultaneous writes to same memory address, mem at addr B gets port B's data
    (wr_a && wr_b && (addr_a == addr_b)) |=> (mem[$past(addr_b)] == $past(data_b_in))
  );

  assert property (@(posedge clk) disable iff (rst)
    // port A reads and port B writes the same addr, A out and mem at addr A get port B's data
    (!wr_a && wr_b && (addr_a == addr_b)) |-> (data_a_out == data_b_in)
    ##1 (mem[$past(addr_a)] == $past(data_b_in))
  );

  assert property (@(posedge clk) disable iff (rst)
    // port A writes and port B reads the same addr, B gets mem at addr B and A out gets A in
    (wr_a && !wr_b && (addr_a == addr_b)) |-> (data_a_out == data_a_in && data_b_out == mem[addr_b])
    ##1 (mem[$past(addr_a)] == $past(data_a_in))
  );



endinterface