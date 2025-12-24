class ram_driver extends uvm_driver#(ram_txn);
  `uvm_component_utils(ram_driver)
  virtual interface ram_if vif;

  function new(input string name = "ram_driver", input uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual ram_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("DRIVER - NOVIF","vif not set")
  endfunction
  
  task run_phase(input uvm_phase phase);
    ram_txn txn;

		drive_idle();

    forever begin
			wait(vif.rst === 0);
      seq_item_port.get_next_item(txn);
    
      @(negedge vif.clk);
			drive_txn(txn);
      
      @(negedge vif.clk);
      drive_idle();

      seq_item_port.item_done();
    end
  endtask

	task drive_txn(ram_txn txn);
  // drive the transaction simultaneously on both ports
		vif.addr_a 		<= txn.addr_a;
    vif.data_a_in <= txn.data_a_in;
    vif.wr_a 			<= txn.wr_a;

    vif.addr_b 		<= txn.addr_b;
    vif.data_b_in <= txn.data_b_in;
    vif.wr_b 			<= txn.wr_b;
	endtask

	task drive_idle();
		vif.wr_a <= 0; 
		vif.wr_b <= 0;
	endtask
endclass