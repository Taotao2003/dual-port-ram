class ram_sb extends uvm_scoreboard;
  `uvm_component_utils(ram_sb)
  function new(input string name="ram_sb",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  uvm_analysis_imp#(ram_txn, ram_sb) imp;
  bit [7:0] ref_mem [0:15]; // 16 x 8-bit memory used for reference
  bit written_flag [0:15];  // flags to track written locations
  
  int unsigned num_errors;
	int unsigned num_passed;

	
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
		imp = new("imp", this);
		for (int i = 0; i < 16; i++) begin 
		  ref_mem[i] = '0; 
          written_flag[i] = 0; 
		end
		num_errors = 0;
		num_passed = 0;
	endfunction
	
  
  function void write(ram_txn txn);
    bit [7:0] expected_a_out, expected_b_out;
    bit same_addr = (txn.addr_a == txn.addr_b);
		bit skip_a = 0; 
		bit skip_b = 0;

    // port A output
    if (txn.wr_a) begin // port A write
      expected_a_out = (txn.wr_b && same_addr) ? txn.data_b_in : txn.data_a_in;

    end else begin // port A read
			if (txn.wr_b && same_addr) begin // port B write to same addr
				expected_a_out = txn.data_b_in;

			end else if (written_flag[txn.addr_a]) begin // addr_a has been written before
				expected_a_out = ref_mem[txn.addr_a];

			end else begin // addr_a has not been written before
				skip_a = 1;
			end
		end
    
		// port B output
		if (txn.wr_b) begin // port B write
			expected_b_out = txn.data_b_in;
			
		end else begin // port B read
			if (written_flag[txn.addr_b]) begin // addr_b has been written before
				expected_b_out = ref_mem[txn.addr_b];

			end else begin // addr_b has not been written before
				skip_b = 1;
			end
		end

		// compare A actual to expected
		if (!skip_a) begin
			if (txn.data_a_out !== expected_a_out) begin
				`uvm_error("RAM_SB", 
					$sformatf("PORT A MISMATCH cycle=%0d wr_a=%0b data_a_in=%0h, addr_a=%0h wr_b=%0b addr_b=%0h expected=%0h got=%0h",
                		txn.cycle, txn.wr_a, txn.data_a_in, txn.addr_a, txn.wr_b, txn.addr_b, expected_a_out, txn.data_a_out))
				num_errors++;
			end else num_passed++;
		end

		// compare B actual to expected
		if (!skip_b) begin
			if (txn.data_b_out !== expected_b_out) begin
				`uvm_error("RAM_SB", 
					$sformatf("PORT B MISMATCH cycle=%0d wr_b=%0b data_b_in=%0h, addr_b=%0h expected=%0h got=%0h",
										txn.cycle, txn.wr_b, txn.data_b_in, txn.addr_b, expected_b_out, txn.data_b_out))
				num_errors++;
			end else num_passed++;
		end

		// scoreboard reference is modeling what the DUT SHOULD have done, not what it appears to have done
		// update reference memory on writes
		if (txn.wr_b) begin
			ref_mem[txn.addr_b] = txn.data_b_in;
			written_flag[txn.addr_b] = 1;
		end

		if (txn.wr_a && !(txn.wr_b && (txn.addr_a == txn.addr_b))) begin
			ref_mem[txn.addr_a] = txn.data_a_in;
			written_flag[txn.addr_a] = 1;
		end
		
  endfunction
  
  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
      `uvm_info("\nPASS_SUMMARY",
      $sformatf("Passed : %0d, Failed : %0d",
                num_passed, num_errors),
      UVM_NONE)
  endfunction
endclass