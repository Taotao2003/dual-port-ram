  package ram_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class ram_txn extends uvm_sequence_item;
`uvm_object_utils(ram_txn)
  rand bit port;
  rand bit wr;
  rand bit [3:0] addr;
  rand bit [7:0] data;
  bit [7:0] exp;

  function new (input string name="ram_txn");
    super.new(name);
  endfunction
endclass

class ram_seqA extends uvm_sequence#(ram_txn);
  `uvm_object_utils(ram_seqA)
  rand int unsigned num_pairs;
  bit unsigned port_id;
  
  function new(input string name = "ram_seq", bit unsigned port_id = 0);
    super.new(name);
    this.port_id = port_id;
    num_pairs = 64;
  endfunction
  
  
  task body();
    ram_txn wr_txn, rd_txn;
    for (int i = 0; i < num_pairs; i++) begin
      // WRITE
      wr_txn = ram_txn::type_id::create($sformatf("wr_txn_%0d", i));
      start_item(wr_txn);
        assert(wr_txn.randomize() with {
          wr   == 1;
          port == port_id;
          // addr & data are rand by default
        }) else `uvm_error("Seq","write randomize failed");
      finish_item(wr_txn);
      `uvm_info("SEQ_WRITE",
        $sformatf("[%0t] WRITE p%0d addr=0x%0h data=0x%0h",
                  $time, port_id, wr_txn.addr, wr_txn.data),
        UVM_MEDIUM)
      
      // READ
      rd_txn = ram_txn::type_id::create($sformatf("rd_txn_%0d", i));
      start_item(rd_txn);
        // force a read, lock addr to the one we just wrote
        assert(rd_txn.randomize() with {
          wr   == 0;
          port == port_id;
          addr == wr_txn.addr;
          // rd_txn.data is ignored by the DUT on a read
        }) else `uvm_error("Seq","read randomize failed");
      finish_item(rd_txn);
//      `uvm_info("SEQ_READ",
//        $sformatf("[%0t] READ  p%0d addr=0x%0h" ,
//                  $time, port_id, rd_txn.addr),
//        UVM_MEDIUM)
      
    end    
  endtask
  
endclass

//class ram_seqB extends uvm_sequence#(ram_txn);
//  `uvm_object_utils(ram_seqB)
//  function new(input string name = "ram_seqB");
//    super.new(name);
//  endfunction
//  task body();
//    repeat(100) begin
//      ram_txn txn = ram_txn::type_id::create("txnB");
//      start_item(txn);
//      assert(txn.randomize() with {port == 0; });
//      finish_item(txn);
//    end
//  endtask
//endclass


class ram_seqr extends uvm_sequencer#(ram_txn);
  `uvm_component_utils(ram_seqr)
  function new(input string name="ram_seqr", input uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

class ram_drvr extends uvm_driver#(ram_txn);
  `uvm_component_utils(ram_drvr)
  virtual ram_if vif;
  function new(input string name = "ram_drvr", input uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual ram_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("DRV/NOVIF","vif not set")
  endfunction
  
  task run_phase(input uvm_phase phase);
    ram_txn txn;
    forever begin
      seq_item_port.get_next_item(txn);
      vif.wrA <= 0; vif.wrB <= 0;
      @(negedge vif.clk);
      if(txn.port == 0) begin // port A
        vif.addrA <= txn.addr;
        vif.dataA_in <= txn.data;
        vif.wrA <= txn.wr;
      end else begin
        vif.addrB <= txn.addr;
        vif.dataB_in <= txn.data;
        vif.wrB <= txn.wr;
      end
      @(negedge vif.clk);
      vif.wrA <= 0; vif.wrB <= 0;
      seq_item_port.item_done();
    end
  endtask
endclass

class ram_mntr extends uvm_monitor;
  `uvm_component_utils(ram_mntr)
  virtual ram_if vif;
  uvm_analysis_port#(ram_txn) ap;
  
  function new(input string name="ram_mntr", input uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction
  
  function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(! uvm_config_db#(virtual ram_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("MNTR/NOVIF","vif not set")
  endfunction
  
  
  task run_phase(uvm_phase phase);
    ram_txn txn, txnA, txnB;
    bit wrA, wrB;
    logic [3:0] aA, aB;
    bit [7:0] dA, dB;
    bit [7:0] eA, eB;
    
    forever begin
      @(posedge vif.clk);
      wrA = vif.wrA; wrB = vif.wrB;
      aA = vif.addrA; aB = vif.addrB;
      dA = vif.dataA_in; dB = vif.dataB_in;
      eA = vif.dataA_out; eB = vif.dataB_out;
      
      // Both write
      if (wrA && wrB) begin
        if (aA == aB) begin
          // same addr => one txn, B wins
          txn = ram_txn::type_id::create($sformatf("wrB_%0t", $time), this);
          txn.port = 1; 
          txn.wr = 1;
          txn.addr = aB; 
          txn.data = dB; 
          txn.exp = eB;
          ap.write(txn);
        end else begin // diff addr
          txnA = ram_txn::type_id::create($sformatf("wrA_%0t", $time), this);
          txnA.port = 0; txnA.wr = 1;
          txnA.addr = aA; txnA.data = dA; txnA.exp = eA;
          ap.write(txnA);
          
          txnB = ram_txn::type_id::create($sformatf("wrB_%0t", $time), this);
          txnB.port = 1; txnB.wr = 1;
          txnB.addr = aB; txnB.data = dB; txnB.exp = eB;
          ap.write(txnB);
        end
      end
      // A writes
      else if (wrA) begin
        txnA = ram_txn::type_id::create($sformatf("wrA_%0t", $time), this);
        txnA.port = 0; txnA.wr = 1;
        txnA.addr = aA; txnA.data = dA; txnA.exp = eA;
        ap.write(txnA);
      end
      // B writes
      else if (wrB) begin
        txnB = ram_txn::type_id::create($sformatf("wrB_%0t", $time), this);
        txnB.port = 1; txnB.wr = 1;
        txnB.addr = aB; txnB.data = dB; txnB.exp = eB;
        ap.write(txnB);
      end
      
      if (!wrA) begin
        txnA = ram_txn::type_id::create($sformatf("rdA_%0t", $time), this);
        txnA.wr   = 0;
        txnA.port = 0;
        txnA.addr = aA;
        txnA.data = 0;
        txnA.exp  = eA;
        ap.write(txnA);
    end

   if (!wrB) begin
      txnB = ram_txn::type_id::create($sformatf("rdB_%0t", $time), this);
      txnB.wr   = 0;
      txnB.port = 1;
      txnB.addr = aB;
      txnB.data = 0;
      txnB.exp  = eB;
      ap.write(txnB);
    end 
      
    end
  endtask
  
endclass

class ram_sb extends uvm_scoreboard;
  `uvm_component_utils(ram_sb)
  function new(input string name="ram_sb",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  uvm_analysis_imp#(ram_txn, ram_sb) imp;
  bit [7:0] ref_mem [0:15];
  bit written_flag [0:15];
  
  int unsigned num_errors;
  int unsigned num_pass;
  int unsigned num_writes;
  int unsigned num_reads;
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
		imp = new("imp", this);
		for (int i = 0; i < 16; i++) begin 
		  ref_mem[i] = '0; written_flag[i] = 0; 
		end
		num_errors = 0; num_pass = 0; num_writes = 0; num_reads = 0;
	endfunction
	
  
  function void write(ram_txn txn);
    if(txn.wr) begin        
      ref_mem[txn.addr] = txn.data;
      written_flag[txn.addr] = 1;
      num_writes++;
    end
    else if (written_flag[txn.addr]) begin 
      num_reads++;
      if(txn.exp !== ref_mem[txn.addr]) begin
        num_errors++;
        `uvm_error("RAM_SB", $sformatf("Mismatch p%0d addr=%0h exp=%0h got=%0h",
                  txn.port, txn.addr, ref_mem[txn.addr], txn.exp))
      end
    end
  endfunction
  
  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    num_pass = num_reads - num_errors;
      `uvm_info("\nPASS_SUMMARY",
      $sformatf("Writes: %0d, Reads: %0d, Passes : %0d, Failures : %0d",
                num_writes, num_reads, num_pass, num_errors),
      UVM_NONE)
  endfunction
endclass

class ram_agent extends uvm_agent;
  `uvm_component_utils(ram_agent)
  ram_seqr seqr;
  ram_drvr drvr;
  ram_mntr mntr;
  
  function new(input string name="ram_agent", uvm_component parent);
    super.new(name, parent);
  endfunction 
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = ram_seqr::type_id::create("seqr",this);
    drvr = ram_drvr::type_id::create("drvr",this);
    mntr = ram_mntr::type_id::create("mntr",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drvr.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class ram_cov extends uvm_subscriber#(ram_txn);
  `uvm_component_utils(ram_cov)
  virtual ram_if vif;
  uvm_analysis_imp#(ram_txn, ram_cov) imp;
  ram_txn txn;
  
  covergroup cg_if;
    // Write-enable coverpoints
    cp_wrA: coverpoint vif.wrA { 
      bins wr = {1}; 
      bins no = {0}; 
     }
    cp_wrB: coverpoint vif.wrB { 
      bins wr = {1}; 
      bins no = {0}; 
    }
    
    // Address coverpoints (0-15)
    cp_addrA: coverpoint vif.addrA { 
      bins addr[] = {[0:15]}; 
    }
    cp_addrB: coverpoint vif.addrB {
      bins addr[] = {[0:15]}; 
    }
    
    // Single port-write cases
    single_A: cross cp_wrA, cp_wrB {
      bins single_write_A = binsof(cp_wrA.wr) && binsof(cp_wrB.no);
    }
    single_B: cross cp_wrA, cp_wrB {
      bins single_write_B = binsof(cp_wrA.no) && binsof(cp_wrB.wr);
    }
    
    // Double write cases (both ports wr=1)
    double_write: cross cp_wrA, cp_wrB {
      bins both_write = binsof(cp_wrA.wr) && binsof(cp_wrB.wr);
    }
    // Double write - same vs different address
    same_addr: coverpoint (vif.wrA && vif.wrB && (vif.addrA == vif.addrB)) {
      bins true = {1}; 
    }
    diff_addr: coverpoint (vif.wrA && vif.wrB && (vif.addrA != vif.addrB)){ 
      bins true = {1}; 
    }
    
    // Per port address hit (ensures every address is ever written)
    coverpoint vif.addrA iff (vif.wrA) {
      bins hitA[] = {[0:15]};  // auto-sized OK here
    }
    // same for port B
    coverpoint vif.addrB iff (vif.wrB) {
      bins hitB[] = {[0:15]};
    }
    
  endgroup 
  
  covergroup cg_txn;
    cp_wr   : coverpoint txn.wr   { bins read = {0}; bins write = {1}; }
    cp_port : coverpoint txn.port { bins A = {0}; bins B = {1}; }
    cp_addr : coverpoint txn.addr { bins addr[] = {[0:15]}; }

    cr_rw_port_addr : cross cp_wr, cp_port, cp_addr;
  endgroup
  
  function new (input string name="ram_cov", input uvm_component parent=null);
    super.new(name,parent);
    imp = new("imp", this);
    cg_if  = new();
    cg_txn = new();
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ram_if)::get(this,"","vif",vif))
      `uvm_fatal("COV/NOVIF","vif not set for coverage");
   endfunction
   
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wait (vif != null);        
    forever @(posedge vif.clk)
      cg_if.sample();        
    endtask
  
  virtual function void write(ram_txn txn);
    this.txn = txn;
    cg_txn.sample();
  endfunction
  
  
endclass

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

class ram_test extends uvm_test;
  `uvm_component_utils(ram_test)
  ram_env env;
  virtual ram_if vif;
  function new(input string name="ram_test",input uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ram_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual ram_if)::get(null,"","vif",vif))
      `uvm_fatal("TEST/NOVIF","vif not set");
    uvm_config_db#(virtual ram_if)::set(this,"*.drvr","vif",vif);
    uvm_config_db#(virtual ram_if)::set(this,"*.mntr","vif",vif);
  endfunction
  
    task run_phase(uvm_phase phase);
      ram_seqA seqA = ram_seqA::type_id::create("seqA");
      ram_seqA seqB = ram_seqA::type_id::create("seqB");
      seqA.port_id = 0;
      seqB.port_id = 1;
      
      phase.raise_objection(this); 
      repeat(10) begin
      fork 
        seqA.start(env.agentA.seqr);                     
        seqB.start(env.agentB.seqr);
//        begin 
//          @(posedge vif.clk);
//          seqA.start(env.agentA.seqr);
//        end
        
      join
      end
      @(posedge vif.clk);
      phase.drop_objection(this);
  endtask
endclass



endpackage 