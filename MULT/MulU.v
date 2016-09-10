`timescale 1ns / 1ps

module MulU(clk,reset,rs1,rs2,rd,Enable,Busy,funct3);
input clk,reset,Enable;
input [31:0] rs1,rs2;
input [11:0] funct3;
output reg[63:0] rd;
output Busy;

reg[3:0] cont1,cont2,cont3;
wire[63:0] Out1,Out0,Out2,Out;
wire [2:0] OutFSM1,OutFSM2,OutFSM3;
reg[15:0] X1,X0,Y1,Y0,M1,M2;
wire [31:0] Z0,Z1,Z2;
reg [31:0] ss1,ss2;
reg sig,signo;
reg [11:0] Op;
wire EnableMul;


FSM_Booth u1 (.clk(clk),.reset(reset),.OutFSM(OutFSM1),.cont(cont1),.Enable(EnableMul)); //FSM1 (X1Y1)
Alg_Booth u2 (.clk(clk),.reset(reset),.R2(Y1),.R1(X1),.Z(Z2),.Busy(OutFSM1[2]),.Em(OutFSM1[0]),.Er(OutFSM1[1])); //Mul 1 (X1Y1)
FSM_Booth u3 (.clk(clk),.reset(reset),.OutFSM(OutFSM2),.cont(cont2),.Enable(EnableMul)); //FSM2 (M1M2)
Alg_Booth u4 (.clk(clk),.reset(reset),.R2(M2),.R1(M1),.Z(Z1),.Busy(OutFSM2[2]),.Em(OutFSM2[0]),.Er(OutFSM2[1])); //Mul 2 (M1M2)
FSM_Booth u5 (.clk(clk),.reset(reset),.OutFSM(OutFSM3),.cont(cont3),.Enable(EnableMul)); //FSM3 (X0Y0)
Alg_Booth u6 (.clk(clk),.reset(reset),.R2(Y0),.R1(X0),.Z(Z0),.Busy(OutFSM3[2]),.Em(OutFSM3[0]),.Er(OutFSM3[1])); //Mul 3 (X0Y0)



always@(funct3,rs1,rs2)
case(funct3)

12'b010010110011: begin
// Algoritmo KARATSUBA MULH (SxS)
	if (rs1[31]) 
		if (rs2[31])begin
			ss1=~rs1+1;
			ss2=~rs2+1;
		end
		else begin
			ss1=~rs1+1;
			ss2 =rs2;
		end
	else if (rs2[31]) begin
		ss1=rs1;
		ss2=~rs2+1;
		end
	else  begin
		ss1=rs1;
		ss2=rs2;
		end
	sig = rs1[31] ^ rs2[31];	
	X1 = ss1[31:16]; // Primos 16 Bits de R1
	X0 = ss1[15:0];
	Y1 = ss2[31:16]; // Primos 16 Bits de R2
	Y0 = ss2[15:0];
	M1 = ss1[31:16] + ss1[15:0]; // (X1+X0)
	M2 = ss2[31:16] + ss2[15:0]; // (Y1 + Y0)	
	end
12'b010100110011: begin
// Algoritmo KARATSUBA MULHSU (SxU)
	if (rs1[31]) ss1=~rs1+1;
	else ss1=rs1;	
	sig = rs1[31] ^ rs2[31];
	X1 = ss1[31:16]; // Primos 16 Bits de R1
	X0 = ss1[15:0];
	Y1 = rs2[31:16]; // Primos 16 Bits de R2
	Y0 = rs2[15:0];
	M1 = ss1[31:16] + ss1[15:0]; // (X1+X0)
	M2 = rs2[31:16] + rs2[15:0]; // (Y1 + Y0)
	end
12'b010110110011: begin
// Algoritmo KARATSUBA MULHU (UxU)
	sig=0;
	X1 = rs1[31:16]; // Primos 16 Bits de R1
	X0 = rs1[15:0];
	Y1 = rs2[31:16]; // Primos 16 Bits de R2
	Y0 = rs2[15:0];
	M1 = rs1[31:16] + rs1[15:0]; // (X1+X0)
	M2 = rs2[31:16] + rs2[15:0]; // (Y1 + Y0)
	end
12'b010000110011: begin
// Algoritmo KARATSUBA MUL (UxU)
	sig = 0;
	X1 = rs1[31:16]; // Primos 16 Bits de R1
	X0 = rs1[15:0];
	Y1 = rs2[31:16]; // Primos 16 Bits de R2
	Y0 = rs2[15:0];
	M1 = rs1[31:16] + rs1[15:0]; // (X1+X0)
	M2 = rs2[31:16] + rs2[15:0]; // (Y1 + Y0)
	end
default: begin
	sig = 0;
	X1 = 0; // Primos 16 Bits de R1
	X0 = 0;
	Y1 = 0; // Primos 16 Bits de R2
	Y0 = 0;
	M1 = 0; // (X1+X0)
	M2 = 0; // (Y1 + Y0)
	end
endcase
assign EnableMul = X1==0&&X0==0&&Y1==0&&Y0==0 ? 1'b0 : Enable;
//Salida Algoritmo KARATSUBA 
	assign Busy =  OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0;
	assign Out2 = Z2<<32;
	assign Out1 = {16'b0,(Z1-Z2-Z0),16'b0};
	assign Out0 = {32'b0,Z0};
	assign Out = Out2+Out1+Out0;
//Asignacion del signo y del H,SU,U a la salida
always@ (posedge clk)
if (OutFSM1[1]==1&&OutFSM2[1]==1&&OutFSM3[1]==1) 
begin
	Op = funct3;
	signo = sig;
end
	

always@ (posedge clk)
case(Op)	
12'b010010110011://MULH (SxS)
	if(OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0)
		begin
		if(signo) rd = ~Out+1;
		else rd =Out;
		end
	else rd = 64'b0;
12'b010100110011://MULHSU (SxU)
	if(OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0)
		begin
		if(signo) rd = ~Out+1;
		else rd =Out;
		end
	else rd = 64'b0;
12'b010110110011: //MULHU (UxU)
	if(OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0) rd = Out;
	else rd = 64'b0;
12'b010000110011: //MUL
	if(OutFSM1[2]==0&&OutFSM2[2]==0&&OutFSM3[2]==0) rd = Out;
	else rd = 64'b0;
default: rd= 64'b0;
endcase

//// Contador 1
always@(posedge clk )
	if (reset==1||cont1==15) cont1 = 4'b0;
	else if (OutFSM1[0]==1) cont1 = cont1 + 4'b0001;
//// Contador 2
always@(posedge clk )
	if (reset==1||cont2==15) cont2 = 4'b0;
	else if (OutFSM2[0]==1) cont2 = cont2 + 4'b0001;
//// Contador 3
always@(posedge clk )
	if (reset==1||cont3==15) cont3 = 4'b0;
	else if (OutFSM3[0]==1) cont3 = cont3 + 4'b0001;	
endmodule
