`timescale 1ns / 1ps

module UTILITY(input clk,input rst,input enable_int,input [31:0] imm,input [31:0] interrup,input [6:0] opcode,input [31:0] rs1,input branch, output [31:0] rd,output [31:0]pc);

reg [63:0] N_CYCLE=0,N_INSTRUC=0,REAL_TIME=0;
reg [31:0] TIME=0,rd_n=0,PC_N=0,PC_N2=0,RD_DATA=0;
wire [31:0] PC_BRANCH, PC_SALTOS, PC_ORIG;

always @(posedge clk )
	begin
		if (rst) N_CYCLE<=0;
		else  N_CYCLE <= N_CYCLE + 1;
	end

always @(posedge clk )
	begin
		if (rst) begin
			TIME<=0;
			REAL_TIME<=0;
		end else if(TIME==100) begin
			TIME<=0;
			REAL_TIME<=REAL_TIME+1;
		end else 
			TIME <= TIME + 1;
	end	
	
always @(posedge clk )
	begin
		if (rst) N_INSTRUC<=0;
		else if (enable_int)  N_INSTRUC <= N_INSTRUC + 1;	
	end

assign PC_SALTOS = PC_N2 + imm;
assign PC_ORIG = PC_N2 + 4;
assign PC_BRANCH = branch ? PC_SALTOS : PC_ORIG;

always @(imm, N_CYCLE, REAL_TIME, N_INSTRUC)
	case (imm)
		32'b00000000000000000000110010000000: RD_DATA = N_CYCLE[63:32];
		32'b00000000000000000000110000000000: RD_DATA = N_CYCLE[31:0];
		32'b00000000000000000000110010000001: RD_DATA = REAL_TIME[63:32];
		32'b00000000000000000000110000000001: RD_DATA = REAL_TIME[31:0];
		32'b00000000000000000000110010000010: RD_DATA = N_INSTRUC[63:32];
		32'b00000000000000000000110000000010: RD_DATA = N_INSTRUC[31:0];
		default: RD_DATA = 0;
	endcase

always @(opcode, rs1, PC_SALTOS, interrup,PC_ORIG,PC_BRANCH)
	case (opcode)
		7'b1100111: PC_N = rs1;
		7'b1101111: PC_N = PC_SALTOS;
		7'b0011010: PC_N = interrup;
		7'b1100011: PC_N = PC_BRANCH;
		default: PC_N = PC_ORIG;
	endcase

   always @(posedge clk)
	begin	
		if (rst) PC_N2<=0;
		else if(enable_int) PC_N2 <= PC_N ;
	end

always @(opcode, RD_DATA,PC_N,imm)
	case (opcode)
		7'b1110011 : rd_n = RD_DATA;
		7'b1101111 : rd_n = PC_ORIG;
		7'b1100111 : rd_n = PC_ORIG;
		7'b0010111 : rd_n = PC_N2+imm;
		default: rd_n = 0;
	endcase
	
assign rd = rd_n;
assign pc = PC_N2;
endmodule
