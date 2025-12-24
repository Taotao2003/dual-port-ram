class ram_base_seq extends uvm_sequence#(ram_txn);
  `uvm_object_utils(ram_base_seq)

  function new(input string name = "ram_seq");
    super.new(name);
  endfunction
  
  // task pre_body();
  //   if (starting_phase != null) begin
  //     starting_phase.raise_objection(this,get_type_name());
  //     `uvm_info(get_type_name(),"raise_objection",UVM_NONE)
  //   end
  // endtask 
  
  virtual task body();
    // to be implemented by derived classes
    `uvm_fatal(get_type_name(),"body not implemented in base class")
  endtask

  // task post_body();
  //   if (starting_phase != null) begin
  //     starting_phase.drop_objection(this,get_type_name());
  //     `uvm_info(get_type_name(),"drop_objection",UVM_NONE)
  //   end
  // endtask
  
endclass


class ram_simple_seq extends ram_base_seq;

  `uvm_object_utils(ram_simple_seq)

  function new ( string name = "ram_simple_seq");
    super.new(name);
  endfunction

  virtual task body();
    ram_txn req;
    `uvm_info(get_type_name(),"Executing sequence with 1000 transactions", UVM_LOW)
    repeat(1000) begin
      req = ram_txn::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
    end
  endtask
endclass 


// class ram_write_seq extends ram_base_seq;

//   `uvm_object_utils(ram_write_seq)

//   function new ( string name = "ram_write_seq");
//     super.new(name);
//   endfunction

//   virtual task body();
//     ram_txn req;
//     `uvm_info(get_type_name(),"Executing write sequence with 1000 transactions", UVM_LOW)
//       req = ram_txn::type_id::create("req");
//       start_item(req);
//       assert(req.randomize() with {
//         wr_a == 1; wr_b == 1;} 
//         (addr_a == addr_b) dist {1:=50, 0:=50};  
//       ); 
//       finish_item(req);
//     end
//   endtask
// endclass