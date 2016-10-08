`timescale 1ns / 1ps
/*
REG_FILE by CKDUR.

Instructions: 
1. Instance REG_FILE, not true_dpram_sclk
2. Connect rd, rs1 and rs2 input/output to their respective buses.
3. Connect rdi, rs1i, rs2i from DECO_INSTR (These are the indexes)
4. If 'rdw_rsrn' is 1 logic, then rd data is written to registers according to rdi
   If 'rdw_rsrn' is 0 logic, then rs1 and rs2 are filled with data from registers according to rs1 and rs2.
   Note: ALWAYS is doing this, if you dont want rd write the registers, you MUST put rdw_rsrn to 0 and maintain rs1i and rs2i constant.
5. Profit!

*/

// Code extracted from: https://www.altera.com/support/support-resources/design-examples/design-software/verilog/ver-true-dual-port-ram-sclk.html
module true_dpram_sclk
(
	input [31:0] data_a,
	input [4:0] addr_a, addr_b,
	input we_a, clk, rst,
	output reg [31:0] q_a, q_b
);
	// Declare the RAM variable
	reg [31:0] ram[31:0];
	
	// Port A
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			ram[addr_a] <= data_a;
		end
		q_a <= addr_a?ram[addr_a]:32'd0;		// Assign zero if index is zero because zero register
		q_b <= addr_b?ram[addr_b]:32'd0;		// Assign zero if index is zero because zero register
	end
	
endmodule

module REG_FILE(
    input clk,
    input rst,
    
	input [31:0] rd,
	input [4:0] rdi,
	input rdw_rsrn,
	output [31:0] rs1,
	input [4:0] rs1i,
	output [31:0] rs2,
	input [4:0] rs2i
	);
	
	wire [31:0] data_a;
	wire [4:0] addr_a, addr_b;
	wire we_a;
	wire [31:0] q_a, q_b;
	
	assign data_a = rd;
	assign addr_a = rdw_rsrn?rdi:rs1i;
	assign addr_b = rs2i;
	assign we_a = rdw_rsrn;
	assign rs1 = q_a;
	assign rs2 = q_b;
	
	true_dpram_sclk MEM_FILE
(
	.data_a(data_a),
	.addr_a(addr_a), .addr_b(addr_b),
	.we_a(we_a), .clk(clk), .rst(rst),
	.q_a(q_a), .q_b(q_b)
);
	
endmodule
