`timescale 1ns / 1ps

interface ram_if #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (input logic clk);

import uvm_pkg::*;
`include "uvm_macros.svh"

  logic rst;
  logic wr_a, wr_b;
  logic [ADDR_WIDTH-1:0] addr_a, addr_b;
  logic [DATA_WIDTH-1:0] data_a_in, data_b_in;
  logic [DATA_WIDTH-1:0] data_a_out, data_b_out;


  // ASSERTIONS
  property p_a_no_zero;
    @(posedge clk) disable iff (rst)
      wr_a |=> !(data_a_in === '0);
  endproperty
  a_no_zero: assert property (p_a_no_zero)
  else `uvm_error("RAM_IF","Port A write with zero/X data_in")

  property p_b_no_zero;
    @(posedge clk) disable iff (rst)
      wr_b |=> !(data_b_in === '0);
  endproperty
  b_no_zero: assert property (p_b_no_zero)
    else `uvm_error("RAM_IF","Port B write with zero/X data_in")

  property p_a_out_on_write_no_collision;
    @(posedge clk) disable iff (rst)
    (wr_a && !(wr_b && (addr_a == addr_b))) |=> (data_a_out == data_a_in);
  endproperty
  a_out_on_write_no_collision: assert property (p_a_out_on_write_no_collision)
    else `uvm_error("RAM_IF","Port A output mismatch on write")

  property p_b_out_on_write;
    @(posedge clk) disable iff (rst)
      wr_b |=> (data_b_out == data_b_in);
  endproperty
  b_out_on_write: assert property (p_b_out_on_write)
  else `uvm_error("RAM_IF","Port B output mismatch on write")

  property p_a_reads_b_writes_same_addr;
  @(posedge clk) disable iff (rst)
    (!wr_a && wr_b && (addr_a == addr_b)) |=> (data_a_out == data_b_in);
  endproperty
  a_reads_b_writes_same_addr: assert property (p_a_reads_b_writes_same_addr)
  else `uvm_error("RAM_IF","Port A output mismatch when B writes same addr")

  property p_a_writes_b_reads_same_addr;
    @(posedge clk) disable iff (rst)
    (wr_a && !wr_b && (addr_a == addr_b)) |=> (data_a_out == data_a_in);
  endproperty
  a_writes_b_reads_same_addr: assert property (p_a_writes_b_reads_same_addr)
  else `uvm_error("RAM_IF","Port A output mismatch when B reads same addr")

endinterface



// MEMORY ASSERTIONS; THEY ARE USELESS BECAUSE MEM IS NOT VISIBLE OUTSIDE DP_RAM
  /* the interface should not accesss mem bc meme is an internal implementation detail of dp_ram,
    not part of the interface. allowing the interface to see it BREAKS encapsulation, makes the testbench bounded
    to ONE SPECIFIC implementation of the ram.
    Internal mem should be checked using a scoreboard
  */

  // // on simultaneous writes to same memory address, mem at addr A gets port B's data
  // assert property (@(posedge clk) disable iff (rst)
  //   (wr_a && wr_b && (addr_a == addr_b)) |=> (mem[$past(addr_a)] == $past(data_b_in))
  // );

  // // on simultaneous writes to same memory address, mem at addr B gets port B's data
  // assert property (@(posedge clk) disable iff (rst)
  //   (wr_a && wr_b && (addr_a == addr_b)) |=> (mem[$past(addr_b)] == $past(data_b_in))
  // );