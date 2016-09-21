`timescale 1ns / 1ps

module sim_IRQf;

	// Inputs
	reg rst;
	reg clk;
	reg savepc;
	reg en;
	reg [11:0] instr;
	reg [31:0] rs1;
	reg [31:0] rs2;
	reg [31:0] inirr;
	reg [31:0] pc;
	reg [31:0] imm;

	// Outputs
	wire [31:0] rd;
	wire [31:0] addrm;
	wire [31:0] outirr;
	wire [31:0] pc_irq;
	wire [31:0] pc_c;
	wire flag;

	// Instantiate the Unit Under Test (UUT)
	IRQ uut (
		.rst(rst), 
		.clk(clk), 
		.savepc(savepc), 
		.en(en), 
		.instr(instr), 
		.rs1(rs1), 
		.rs2(rs2), 
		.inirr(inirr), 
		.pc(pc), 
		.imm(imm), 
		.rd(rd), 
		.addrm(addrm), 
		.outirr(outirr), 
		.pc_irq(pc_irq), 
		.pc_c(pc_c), 
		.flag(flag)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		clk = 1;
		savepc = 0;
		en = 0;
		instr = 0;
		rs1 = 0;
		rs2 = 0;
		inirr = 0;
		pc = 0;
		imm = 0;

		// Wait 100 ns for global reset to finish
		#100;
      rst=1;
		#20;
		savepc=1;
		pc=5;
		#20;
		pc=0;
		#20;
		savepc=0;
		#20;
		en=1;
		#15;
		// Add stimulus here
		inirr=4;
		#10;
		inirr=0;
		#30;
		inirr=8;
		#20;
		inirr=1024;
		#20;
		inirr=256;
		#20;
		inirr=0;
		#10;
		instr=12'b000000111001;
		#20;
		instr=0;
		#55;
		instr=12'b001100011000;
		rs1=7;
		imm=11'b10100001000;
		#20;
		instr=0;
		rs1=0;
		imm=2;
		#20;
		instr=0;
		rs1=0;
		imm=0;
		#20;
		instr=12'b001110011000;
		#20;
		instr=0;
		#20;
		instr=12'b000000011000;
		rs1=32;
		imm=4;
		#20;
		instr=12'b000010011000;
		#40;
		instr=0;
		//rs1=0;
		imm=0;
		#40;
		instr=12'b000100011000;
		#20;
		instr=12'b001010011000;
		#20;
		instr=0;
		#20;
		inirr=5'b10101;
		#20;
		inirr=0;
		#20
		instr=12'b001000011000;
		#40
		instr=0;

		
	end
	
   always	#10 clk = !clk;  
      
endmodule

