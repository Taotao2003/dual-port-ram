class ram_base_test extends uvm_test;
  `uvm_component_utils(ram_base_test)

  ram_env env;

  function new(string name="ram_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ram_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(),
              "Base test: environment built",
              UVM_LOW)
  endfunction
endclass
