`uvm_analysis_imp_decaxi_portl(_ahb)
`uvm_analysis_imp_decl(_axi)

class ahb_to_axi_scoreboard extends uvm_scoreboard;

`uvm_component_utils(ahb_to_axi_scoreboard)

uvm_analysis_imp_ahb #(ahb_seq_item) master_ahb;
uvm_analysis_imp_axi #(axi_seq_item) slave_axi;

int ahb_q_index;
ahb_seq_item  ahb_master_q[][$];
axi_seq_item  axi_slave_exp_q[$];
axi_seq_item  axi_slave_act_q[$];
bit [1:0]htrans_prv;  //previous transaction type
int total_ahb_tx;
int ahb_burst_completed;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ahb_q_index=0;
    ahb_burst_completed=0;
  endfunction


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_ahb = new("master_ahb", this);
    slave_axi = new("slave_axi", this);
  endfunction



    function void write_ahb( ahb_seq_item  ahb_tx);
        uvm_info("SCRB","AHB Data from SB",UVM_LOW)
	
	if(ahb_tx.htrans==0)begin //if IDLE State
        	if(htrans_prv==3 || htrans_prv==2) ahb_q_index+=1; //Check 
	end
	if(ahb_tx.htrans==1)begin  //if BUSY State
        	if(htrans_prv==3 || htrans_prv==2) ahb_q_index+=0; //Check 
	end

	if(ahb_tx.htrans==2)begin  //if NONSEQ State
        	if(htrans_prv==3 || htrans_prv==2) ahb_q_index+=1; //Check 
		ahb_master_q[ahb_q_index].push_back(ahb_tx);
	end
	 
        if(ahb_tx.htrans==3)begin  //if SEQ state
        	ahb_master_q[ahb_q_index].push_back(ahb_tx);
        end
        if( ahb_tx.htrans==3 && (htrans_prv==2||htrans_prv==3) )begin
        	ahb_q_index=ahb_q_index; //No Change
        end
	
	htrans_prv=ahb_tx.htrans;     //previous transaction type
	
	//axi_txn= convert_to_axi4(ahb_tx);
        //axi_master_exp_q.push_back(axi_tx);
        
	uvm_info("SCRB",$sformatf("Size of the Queue = %d", ahb_master_q.size),UVM_LOW)

    endfunction

    function void write_axi( axi_seq_item  axi_tx);
        uvm_info("SCRB","AXI Data from SB",UVM_LOW)
        axi_master_act_q.push_back(axi_tx);
        uvm_info("SCRB",$sformatf("Size of the Queue = %d", ahb_master_act_q.size),UVM_LOW)
   
    endfunction

	virtual task run_phase(uvm_phase phase);
	super.run_phase(phase);
	fork
		forever begin
			if(ahb_q_index!=ahb_burst_completed) begin 
				axi_txn= convert_to_axi4(ahb_master_q[abh_q_index-1]);
        			axi_slave_exp_q.push_back(axi_tx);
        			`uvm_info("SCRB",$sformatf("Size of the Queue = %d", ahb_master_q.size),UVM_LOW)
					
				ahb_burst_completed+=1;
			end
		end
		forever begin
			if(axi_slave_act_q.size()!=0 && axi_slave_exp_q.size()!=0 ) begin 
				
        			axi_expected = axi_slave_exp_q.pop_front();
        			axi_actual = axi_slave_act_q.pop_front();
				if(axi_expected.compare(axi_actual)) begin	
        				`uvm_info("SCRB","PASS",UVM_LOW)
				end
				else begin	
        				`uvm_info("SCRB","AXI Transaction Mismatch",UVM_LOW)
				end
					
			end
		end
	
	join
	endtask



function void convert_to_axi4( ahb_seq_item ahb_tx);
	axi_seq_item axi_tx;

	if(ahb_tx.htrans==2b'2)  //Htrans == NONSEQ
	begin
		if(ahb_tx.hwrite==1) begin
			axi_tx.awaddr = ahb_tx.addr;
			axi_tx.awlen = ahb_axi_len (ahb_tx.hburst);
			axi_tx.awsize = ahb_tx.hsize;
			axi_tx.awburst = ahb_axi_burst(ahb_tx.hburst);
			//axi_tx.awlock = -------;
		end
		else begin
                        axi_tx.araddr = ahb_tx.addr;
                        axi_tx.arlen = ahb_axi_len (ahb_tx.hburst);
                        axi_tx.arsize = ahb_tx.hsize;
                        axi_tx.arburst = ahb_axi_burst(ahb_tx.hburst);
                        //axi_tx.arlock = -------;
		end


	end
	else if(ahb_tx.htrans==2b'3)  //Htrans == SEQ
	begin

	end
	endfunction

function bit[3:0] ahb_axi_len (bit[2:0] hburst);
	case(hburst)
	3'b000: ahb_axi_len = 0;  //AHB single burst ====>> AXI Single burst
	3'b001: ahb_axi_len = 0;  //AHB Undefined burst ====>> AXI Single burst
	3'b010: ahb_axi_len = 3;  //AHB WRAP4 burst ====>> AXI burst Len = 4
	3'b011: ahb_axi_len = 3;  //AHB INCR4 burst ====>> AXI burst Len = 4
	3'b100: ahb_axi_len = 7;  //AHB WRAP8 burst ====>> AXI burst Len = 8
	3'b101: ahb_axi_len = 7;  //AHB INCR8 burst ====>> AXI burst Len = 8 
	3'b110: ahb_axi_len = 15; //AHB WRAP16 burst ====>> AXI burst Len = 16
        3'b111: ahb_axi_len = 15; //AHB INCR16 burst ====>>  AXI burst Len = 16
	endcase
endfunction	

function bit[1:0] ahb_axi_burst (bit[2:0] hburst);
        case(hburst)
        3'b000: ahb_axi_burst = 0;  //AHB single burst ====>> FIXED 
        3'b001: ahb_axi_burst = 0;  //AHB undefined burst ====>> FIXED
        3'b010: ahb_axi_burst = 2;  //AHB WRAP4 burst ====>> WRAP 
        3'b011: ahb_axi_burst = 1;  //AHB INCR4 burst ====>> INCR 
        3'b100: ahb_axi_burst = 2;  //AHB WRAP8 burst ====>> WRAP 
        3'b101: ahb_axi_burst = 1;  //AHB INCR8 burst ====>> INCR 
        3'b110: ahb_axi_burst = 2; //AHB WRAP16 burst ====>> WRAP 
        3'b111: ahb_axi_burst = 1; //AHB INCR16 burst ====>> INCR 
        endcase
endfunction



endclass
