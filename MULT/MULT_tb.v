`timescale 1ns / 1ps

module MULT_tb;
parameter clkperiodo=2;
parameter sword = 32;

	// Inputs
	reg clk;
	reg reset;
	reg Enable;
	reg [11:0]funct3;
	reg [31:0] rs1;
	reg [31:0] rs2;
	reg [32:0] rs1e;
	reg [32:0] rs2e;

	// Outputs
	wire [31:0] rd;
	reg [63:0] vmult;
	reg [31:0] rde;
	wire Done;
	
	localparam tries = 30;
	integer i, j, error, l;
	
	// Instantiate the Unit Under Test (UUT)
	MULT uut (
		.clk(clk), 
		.reset(reset), 
	    .Enable(Enable),
		.rs1(rs1), 
		.rs2(rs2), 
		.rd(rd),
		.Done(Done),
		.funct3(funct3)
	);
	always #(clkperiodo/2) clk =!clk;
	
	// Task for expect something (helper)
	task aexpect;
		input [sword-1:0] av, e;
		begin
		 if (av == e)
			$display ("TIME=%t." , $time, " Actual value of mult=%b, expected is %b. MATCH!", av, e);
		 else
		  begin
			$display ("TIME=%t." , $time, " Actual value of mult=%b, expected is %b. ERROR!", av, e);
			error = error + 1;
		  end
		end
	endtask
	
	
	initial begin
		// Initialize Inputs
		clk = 1'b0;
		reset = 1'b0;
		Enable = 1'b0;
		funct3 = 12'b0;
		rs1 = 32'b0;
		rs2 = 32'b0;
		vmult = 0;
		i = 0; error = 0;
		// Wait 100 ns for global reset to finish
	  #(clkperiodo*5);
		reset = 1'b1;
		#(clkperiodo*5);
		// Begin testing:
		funct3 = 12'b010000110011; // MUL (UxU)
		for(i = 0; i < tries; i=i+1) begin
			rs1e = $unsigned($random()); rs1 = rs1e[31:0];
			rs2e = $unsigned($random()); rs2 = rs2e[31:0];
			vmult = $signed(rs1e)*$signed(rs2e);
			rde = vmult[31:0];
			Enable = 1'b0;
			#(clkperiodo*5);
			Enable = 1'b1;
			#(clkperiodo*5);
			while(!Done) #(clkperiodo);
			Enable = 1'b0;
			aexpect(rd, rde);
		end
		funct3 = 12'b010100110011; //MULHSU (SxU)
		for(i = 0; i < tries; i=i+1) begin
			rs1e = $signed($random()); rs1 = rs1e[31:0];
			rs2e = $unsigned($random()); rs2 = rs2e[31:0];
			vmult = $signed(rs1e)*$signed(rs2e);
			rde = vmult[63:32];
			Enable = 1'b0;
			#(clkperiodo*5);
			Enable = 1'b1;
			#(clkperiodo*5);
			while(!Done) #(clkperiodo);
			Enable = 1'b0;
			aexpect(rd, rde);
		end
		funct3 = 12'b010010110011; //MULH (SxS)
		for(i = 0; i < tries; i=i+1) begin
			rs1e = $signed($random()); rs1 = rs1e[31:0];
			rs2e = $signed($random()); rs2 = rs2e[31:0];
			vmult = $signed(rs1e)*$signed(rs2e);
			rde = vmult[63:32];
			Enable = 1'b0;
			#(clkperiodo*5);
			Enable = 1'b1;
			#(clkperiodo*5);
			while(!Done) #(clkperiodo);
			Enable = 1'b0;
			aexpect(rd, rde);
		end
		funct3 = 12'b010110110011; // MULHU (UxU)
		for(i = 0; i < tries; i=i+1) begin
			rs1e = $unsigned($random()); rs1 = rs1e[31:0];
			rs2e = $unsigned($random()); rs2 = rs2e[31:0];
			vmult = $signed(rs1e)*$signed(rs2e);
			rde = vmult[63:32];
			Enable = 1'b0;
			#(clkperiodo*5);
			Enable = 1'b1;
			#(clkperiodo*5);
			while(!Done) #(clkperiodo);
			Enable = 1'b0;
			aexpect(rd, rde);
		end

		if (error == 0)
			$display("All match");
		else
			$display("Mismatches = %d", error);
		$finish;

	end
      
endmodule

