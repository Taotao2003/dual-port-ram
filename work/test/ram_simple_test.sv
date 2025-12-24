class ram_simple_test extends ram_base_test;
  `uvm_component_utils(ram_simple_test)

  function new(string name="ram_simple_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ram_simple_seq seq;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting simple RAM test", UVM_LOW)

    seq = ram_simple_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    `uvm_info(get_type_name(), "Simple RAM test finished", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
