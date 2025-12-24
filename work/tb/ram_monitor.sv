class ram_monitor extends uvm_monitor;
  `uvm_component_utils(ram_monitor)
  virtual ram_if vif;
  uvm_analysis_port#(ram_txn) ap;

	int unsigned cycle;
  
  function new(input string name="ram_mntr", input uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
		cycle = 0;
  endfunction
  
  function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(! uvm_config_db#(virtual ram_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("MONITOR - NOVIF","vif not set")
  endfunction
  
  
  task run_phase(uvm_phase phase);
    ram_txn txn;
		
    
    forever begin
      @(posedge vif.clk);
      if (vif.rst) continue;

      #1step;
			// create transaction for each cycle
			txn = ram_txn::type_id::create($sformatf("ram_txn_%0d", cycle), this);

			txn.cycle = cycle;

			// sample and send both ports simultaneously
			txn.port_a = 1;
			txn.wr_a = vif.wr_a;
			txn.addr_a = vif.addr_a;
			txn.data_a_in = vif.data_a_in;
			txn.data_a_out = vif.data_a_out;
			
			txn.port_b = 1;
			txn.wr_b = vif.wr_b;
			txn.addr_b = vif.addr_b;
			txn.data_b_in = vif.data_b_in;
			txn.data_b_out = vif.data_b_out;

			txn.collision = (vif.wr_a && vif.wr_b && (vif.addr_a == vif.addr_b)) ? 1 : 0;

			ap.write(txn);

			cycle++;
    end 
      
  endtask
  
endclass