class ram_env extends uvm_env;
  `uvm_component_utils(ram_env)

  ram_agent agentA, agentB;
  ram_sb sb;
  ram_cov cov;

  
  function new(input string name="ram_env",input uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agentA = ram_agent::type_id::create("agentA", this);
    agentB = ram_agent::type_id::create("agentB", this);
    sb = ram_sb::type_id::create("sb", this);
    cov = ram_cov::type_id::create("cov", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agentA.mntr.ap.connect(sb.imp);
    agentB.mntr.ap.connect(sb.imp);
    agentA.mntr.ap.connect(cov.imp);
    agentB.mntr.ap.connect(cov.imp);
  endfunction 
endclass