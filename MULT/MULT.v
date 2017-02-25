`timescale 1ns / 1ps

module FSM_Booth
	#(
	parameter  COUNT_BIT = 5,
	parameter  BITS_BOOTH = 16
	)
	(input clk,reset,Enable,
	input[COUNT_BIT-1:0] cont,
	output reg [2:0] OutFSM);
	

	reg [1:0]state,nextState;


	//Asignacion asincrona de estados
	always@(state,cont,Enable)
	case(state)
	2'b00:
		if(Enable==1) nextState = 2'b01;
		else nextState = 2'b00;
	2'b01:
		nextState = 2'b10;
	2'b10:
		if(cont==BITS_BOOTH) nextState = 2'b11;
		else nextState = 2'b10;
	2'b11:
		if(Enable==0) nextState = 2'b00;
		else nextState = 2'b11;
	//default: nextState = 2'b00;
	endcase
	//Asignacion sincrona: Actualizacion del estado
	always@(posedge clk)
	begin
		if(reset==0) state = 2'b0;
		else state = nextState;
	end
	//Asignacion de las salidas
	always@(state)
		if(state==2'b00) OutFSM = 3'b100;
		else if (state==2'b01) OutFSM = 3'b110;
		else if (state==2'b10) OutFSM = 3'b101;
		else OutFSM = 3'b000;
	
endmodule 

module Alg_Booth
	#(
	parameter  SWORD = 17
	)
	(input clk,reset,Busy,Em,Er,
	input [SWORD-1:0] R2,R1,
	output[SWORD*2-1:0] Z);
	


	//reg[16:0] Q2;
	reg[SWORD-1:0] Q1,aux;
	reg[SWORD*2:0] S,address2,subres2;
	wire[SWORD-1:0] NQ1;

	assign NQ1 = ~Q1+1;
	//FF-D de R1 y R2
	always@ (posedge clk)
	begin
		if(!reset) begin
			Q1 = 0;
			S = 0;
		end else if(Er)	begin
			Q1 =R1;
			S = {{SWORD{1'b0}}, R2, 1'b0};
		end else if(Em) begin
			case(S[1:0])
				2'b00:begin 
					S = {S[SWORD*2],S[SWORD*2:1]};
					//S = {1'b0,S[SWORD*2:1]};
				end
				2'b01:begin
					aux = S[SWORD*2:SWORD+1]+Q1;
					S = {aux[SWORD-1],aux,S[SWORD:1]};
					//S = {1'b0,aux,S[SWORD:1]};
				end
				2'b10:begin
					aux = S[SWORD*2:SWORD+1]+NQ1;
					S = {aux[SWORD-1],aux,S[SWORD:1]};
					//S = {1'b0,aux,S[SWORD:1]};
				end
				2'b11:begin 
					S = {S[SWORD*2],S[SWORD*2:1]};
					//S = {1'b0,S[SWORD*2:1]};
				end
			endcase
		end	else begin
			Q1 = Q1;
			S = S;
		end
	end


	assign Z = Busy ? 0 : S[SWORD*2:1];


endmodule

module MULT(input clk,reset,Enable,
	input [31:0] rs1,rs2,
	input [11:0] codif,
	output [31:0] rd,
	output reg is_oper,
	output reg Done);

	localparam COUNT_BIT = 5;
	localparam BITS_BOOTH = 16;
	

	reg[COUNT_BIT-1:0] cont1,cont2,cont3;
	wire[63:0] Out1,Out0,Out2,Out;
	wire [2:0] OutFSM1,OutFSM2,OutFSM3;
	reg[16:0] X1,X0,Y1,Y0;
	reg[17:0] M1,M2;
	wire [33:0] Z0,Z2;
	wire [35:0] Z1,Z1_Z2_Z0,NZ2,NZ0;
	reg [31:0] ss1,ss2,srd;
	reg [16:0] ss1_ss1;
	reg [16:0] ss2_ss2;
	reg [63:0] rdu;
	reg sig,signo;
	reg [11:0] Op;
	wire EnableMul;
	wire Ready;
	//reg is_oper;


	FSM_Booth u1 (.clk(clk),.reset(reset),.OutFSM(OutFSM1),.cont(cont1),.Enable(EnableMul)); //FSM1 (X1Y1)
	Alg_Booth u2 (.clk(clk),.reset(reset),.R2(Y1),.R1(X1),.Z(Z2),.Busy(OutFSM1[2]),.Em(OutFSM1[0]),.Er(OutFSM1[1])); //Mul 1 (X1Y1)
	FSM_Booth #(.BITS_BOOTH(17)) u3 (.clk(clk),.reset(reset),.OutFSM(OutFSM2),.cont(cont2),.Enable(EnableMul)); //FSM2 (M1M2)
	Alg_Booth #(.SWORD(18)) u4 (.clk(clk),.reset(reset),.R2(M2),.R1(M1),.Z(Z1),.Busy(OutFSM2[2]),.Em(OutFSM2[0]),.Er(OutFSM2[1])); //Mul 2 (M1M2)
	FSM_Booth u5 (.clk(clk),.reset(reset),.OutFSM(OutFSM3),.cont(cont3),.Enable(EnableMul)); //FSM3 (X0Y0)
	Alg_Booth u6 (.clk(clk),.reset(reset),.R2(Y0),.R1(X0),.Z(Z0),.Busy(OutFSM3[2]),.Em(OutFSM3[0]),.Er(OutFSM3[1])); //Mul 3 (X0Y0)



	always@* begin
		case(codif)
			12'b010010110011: begin
				// Algoritmo KARATSUBA MULH (SxS)
				if (rs1[31]) ss1 = ~rs1+1;
				else ss1 = rs1;
				if (rs2[31]) ss2 = ~rs2+1;
				else ss2 = rs2;
				sig = rs1[31] ^ rs2[31];
				is_oper = 1;
				srd = rdu[63:32];
			end
			12'b010100110011: begin
				// Algoritmo KARATSUBA MULHSU (SxU)
				if (rs1[31]) ss1 = ~rs1+1;
				else ss1 = rs1;	
				ss2 = rs2;
				sig = rs1[31];
				is_oper = 1;
				srd = rdu[63:32];
			end
			12'b010110110011: begin
				// Algoritmo KARATSUBA MULHU (UxU)
				ss1 = rs1;
				ss2 = rs2;
				sig = 0;
				is_oper = 1;
				srd = rdu[63:32];
			end
			12'b010000110011: begin
				// Algoritmo KARATSUBA MUL (UxU)
				ss1 = rs1;
				ss2 = rs2;
				sig = 0;
				is_oper = 1;
				srd = rdu[31:0];
			end
			default: begin
				ss1 = rs1;
				ss2 = rs2;
				sig = 0;
				is_oper = 0;
				srd = 32'hxxxxxxxx;
			end
		endcase
		X1 = {1'b0, ss1[31:16]}; // First 16 Bits of R1
		X0 = {1'b0, ss1[15:0]};
		Y1 = {1'b0, ss2[31:16]}; // First 16 Bits of R2
		Y0 = {1'b0, ss2[15:0]};
		ss1_ss1 = ss1[31:16] + ss1[15:0];
		M1 = {1'b0, ss1_ss1}; // (X1+X0)
		ss2_ss2 = ss2[31:16] + ss2[15:0];
		M2 = {1'b0, ss2_ss2}; // (Y1+Y0)	
	end
	assign rd = is_oper?srd:32'hzzzzzzzz;
	
	assign EnableMul = /*X1==0&&X0==0&&Y1==0&&Y0==0 ? 1'b0 :*/ (Enable & is_oper);
	//Salida Algoritmo KARATSUBA 
	assign Ready = OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0;
	assign NZ2 = -$signed(Z2);
	assign NZ0 = -$signed(Z0);
	assign Z1_Z2_Z0 = (Z1+NZ2+NZ0);
	assign Out2 = Z2<<32;
	assign Out1 = {{14{Z1_Z2_Z0[33]}}, Z1_Z2_Z0}<<16;
	assign Out0 = {{30{Z0[33]}}, Z0};
	assign Out = Out2+Out1+Out0;
	

	always@ (posedge clk) begin
		if(Ready) begin
			if(sig) rdu = ~Out+1;
			else rdu = Out;
			Done = 1;
		end else if(is_oper) begin
			Done = 0;
			rdu = 64'b0;
		end	else begin
			rdu = 64'b0;
			Done = 0;
		end
	end

	//// Contador 1
	always@(posedge clk )
		if (reset==0||cont1==BITS_BOOTH) cont1 = 0;
		else if (OutFSM1[0]==1) cont1 = cont1 + 1;
	//// Contador 2
	always@(posedge clk )
		if (reset==0||cont2==17) cont2 = 0;
		else if (OutFSM2[0]==1) cont2 = cont2 + 1;
	//// Contador 3
	always@(posedge clk )
		if (reset==0||cont3==BITS_BOOTH) cont3 = 0;
		else if (OutFSM3[0]==1) cont3 = cont3 + 1;	
endmodule
