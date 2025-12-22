class ram_txn extends uvm_sequence_item;
`uvm_object_utils(ram_txn)
  rand bit port_a, port_b;
  rand bit wr_a, wr_b;
  rand bit [3:0] addr_a, addr_b;
  rand bit [7:0] data_a, data_b;
  bit [7:0] expected_data_a, expected_data_b;

  function new (input string name="ram_txn");
    super.new(name);
  endfunction

  constraint c_ports_fixed {
    // both ports always active
    port_a == 1;
    port_b == 1;
  }

  constraint no_write_zero { 
    // data should not be zero on write
    if (wr_a) data_a != 8'h00;
    if (wr_b) data_b != 8'h00;
  }

  constraint force_collision {
    // force collision 36% of the time
    wr_a dist {1:=60, 0:=40};
    wr_b dist {1:=60, 0:=40};
    if (wr_a && wr_b) addr_a == addr_b; 
  }
endclass