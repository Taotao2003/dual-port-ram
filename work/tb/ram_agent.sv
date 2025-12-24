class ram_agent extends uvm_agent;
  
  ram_seqr      seqr;
  ram_driver    drvr;
  ram_monitor   mntr;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

	`uvm_component_utils_begin(ram_agent)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_component_utils_end
  
  function new(input string name="ram_agent", uvm_component parent);
    super.new(name, parent);
  endfunction 
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
		mntr = ram_monitor::type_id::create("mntr",this);

		if (is_active == UVM_ACTIVE) begin
			seqr = ram_seqr::type_id::create("seqr",this);
			drvr = ram_driver::type_id::create("drvr",this);
		end
  endfunction
  
  function void connect_phase(uvm_phase phase);
		if (is_active == UVM_ACTIVE)
			drvr.seq_item_port.connect(seqr.seq_item_export);
	endfunction
endclass