`timescale 1ns / 1ps

module sim_MulU;
parameter clkperiodo=2;
parameter NUM1p = {24'b0,8'b01101001}; // +105
parameter NUM1n = {24'b111111111111111111111111,8'b10010111}; // -105 (151 un s igne d )
parameter NUM2p = {24'b0,8'b01101011}; // +107
parameter NUM2n = {24'b111111111111111111111111,8'b10010101}; //-107

	// Inputs
	reg clk;
	reg reset;
	reg Enable;
	reg [11:0]funct3;
	reg [31:0] rs1;
	reg [31:0] rs2;

	// Outputs
	wire [63:0] rd;
	wire Busy;

	// Instantiate the Unit Under Test (UUT)
	MulU uut (
		.clk(clk), 
		.reset(reset), 
	   .Enable(Enable),
		.rs1(rs1), 
		.rs2(rs2), 
		.rd(rd),
		.Busy(Busy),
		.funct3(funct3)
	);
	always #(clkperiodo/2) clk =!clk;
	initial begin
		// Initialize Inputs
		clk = 1'b0;
		reset = 1'b1;
		Enable = 1'b0;
		funct3 = 12'b0;
		rs1 = 32'b0;
		rs2 = 32'b0;
		// Wait 100 ns for global reset to finish
		#(clkperiodo*5);
		rs1= NUM1p;
		rs2 = NUM2p;
		reset = 1'b0;
		Enable = 1'b1;
		funct3 = 12'b010000110011; // MULHU (UxU)
      #(clkperiodo*19);
		Enable = 1'b1;
		rs1 = NUM1n;
		rs2 = NUM2p;
		reset = 1'b0;
		funct3 = 12'b010100110011;//MULHSU (SxU)
		#(clkperiodo*13);
		rs1 = NUM1p;
		rs2 = NUM2n;
		reset = 1'b0;
		funct3 = 12'b010010110011;//MULH (SxS)
		Enable = 1'b0;
      #(clkperiodo*6);
		Enable = 1'b0;
		rs1 = NUM1p;
		rs2 = NUM2p;
		reset = 1'b0;
		funct3 = 12'b001100011000; //otro valor
		#(clkperiodo*13);
		rs1 = NUM1n;
		rs2 = NUM2n;
		funct3 = 12'b001100011000; //otro valor
		reset = 1'b0;
		Enable = 1'b1;
		#(clkperiodo*10);
		Enable = 1'b0;
		rs1 = NUM2p;
		rs2 = NUM2n;
		reset = 1'b0;
		funct3 = 12'b010100110011;//MULHSU (SxU)
      #(clkperiodo*200);

		$finish;
		// Add stimulus here

	end
      
endmodule

