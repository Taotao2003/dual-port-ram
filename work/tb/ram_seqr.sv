class ram_seqr extends uvm_sequencer#(ram_txn);
  `uvm_component_utils(ram_seqr)
  function new(input string name="ram_seqr", input uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass