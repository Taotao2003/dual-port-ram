package ram_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
    
    
	`include "ram_txn.sv"
	`include "ram_seq.sv"
	
	`include "ram_seqr.sv"
	`include "ram_driver.sv"
	`include "ram_monitor.sv"
	`include "ram_agent.sv"

	`include "ram_sb.sv"

	`include "ram_env.sv"
	
	// tests
	`include "../test/ram_base_test.sv"
	`include "../test/ram_simple_test.sv"
    
endpackage