class ram_write_test extends ram_base_test;
  `uvm_component_utils(ram_write_test)

  function new(string name="ram_write_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ram_write_seq seq;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting write RAM test", UVM_LOW)

    seq = ram_write_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    `uvm_info(get_type_name(), "Write RAM test finished", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
