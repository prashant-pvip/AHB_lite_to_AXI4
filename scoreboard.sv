`uvm_analysis_imp_decaxi_portl(_ahb)
`uvm_analysis_imp_decl(_axi)

class ahb_to_axi_scoreboard extends uvm_scoreboard;

`uvm_component_utils(ahb_to_axi_scoreboard)

uvm_analysis_imp_ahb #(ahb_seq_item) master_ahb;
uvm_analysis_imp_axi #(axi4_seq_item) slave_axi;


ahb_seq_item  ahb_master_q[$];
axi_seq_item  axi_slave_exp_q[$];
axi_seq_item  axi_slave_act_q[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_ahb = new("master_ahb", this);
    slave_axi = new("slave_axi", this);
  endfunction



    function void write_ahb( ahb_seq_item  ahb_tx);
        uvm_info("SCRB","AHB Data from SB",UVM_LOW)
        ahb_master_q.push_back(ahb_tx);
	axi_txn= convert_to_axi4(ahb_tx);
        axi_master_exp_q.push_back(axi_tx);
        uvm_info("SCRB",$sformatf("Size of the Queue = %d", ahb_master_q.size),UVM_LOW)

    endfunction

    function void write_axi( axi_seq_item  axi_tx);
        uvm_info("SCRB","AXI Data from SB",UVM_LOW)
        axi_master_act_q.push_back(axi_tx);
        uvm_info("SCRB",$sformatf("Size of the Queue = %d", ahb_master_act_q.size),UVM_LOW)
   
    endfunction

function void convert_to_axi4( ahb_seq_item ahb_tx);
	axi_seq_item axi_tx;

	if(ahb_tx.htrans==2b'2)  //Htrans == NONSEQ
	begin
		axi_tx.awaddr = ahb_tx.addr;
		axi_tx.awsize = ahb_tx.hsize;
		axi_tx.awlen = ahb_axi_len (ahb_tx.hburst);

		axi_tx.awburst = ahb_tx.hwrite ?ahb_axi_burst(ahb_tx.hburst) : 0;
		
		axi_tx.arburst = ahb_tx.hwrite ? 0 : ahb_tx.hburst;
		axi_tx.addr = ahb_tx.addr;
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
        3'b110: ahb_axi_burst = 2;  //AHB WRAP16 burst ====>> WRAP 
        3'b111: ahb_axi_burst = 1;  //AHB INCR16 burst ====>> INCR 
        endcase
endfunction



endclass
