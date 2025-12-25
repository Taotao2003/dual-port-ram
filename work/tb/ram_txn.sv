class ram_txn extends uvm_sequence_item;
`uvm_object_utils(ram_txn)
  rand bit port_a, port_b;
  rand bit wr_a, wr_b;
  rand bit [3:0] addr_a, addr_b;
  rand bit [7:0] data_a_in, data_b_in;
  bit [7:0] data_a_out, data_b_out;

  int unsigned cycle;
  bit collision;


  function new (input string name="ram_txn");
    super.new(name);
  endfunction

  constraint ports_fixed {
    // both ports always active
    port_a == 1;
    port_b == 1;
  }

  constraint no_write_zero { 
    // data should not be zero on write
    if (wr_a) data_a_in != 8'h00;
    if (wr_b) data_b_in != 8'h00;
  }

  constraint writes_dist {
    // make writes happen 60% of the time
    wr_a dist {1:=80, 0:=20};
    wr_b dist {1:=80, 0:=20};
  }
endclass