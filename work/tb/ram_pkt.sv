class ram_txn extends uvm_sequence_item;
`uvm_object_utils(ram_txn)
  rand bit port;
  rand bit wr;
  rand bit [3:0] addr;
  rand bit [7:0] data;
  bit [7:0] exp;

  function new (input string name="ram_txn");
    super.new(name);
  endfunction

  constraint wr_en {;}
endclass