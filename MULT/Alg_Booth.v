`timescale 1ns / 1ps
module Alg_Booth(clk,reset,R2,R1,Z,Busy,Em,Er);
input clk, reset,Busy,Em,Er;
input [15:0] R2,R1;
output[31:0] Z;


reg[16:0] Q2,subres,addres;
reg[15:0] Q1;
reg[32:0] S,addres2,subres2;
wire[15:0] NQ1;

assign NQ1 = ~Q1+{15'b0,1'b1};
//FF-D de R1 y R2
always@ (posedge clk)
begin
	if(reset)
	begin
		Q1 = 17'b0;
		Q2 = 17'b0;
		S = 33'b0;
	end
	else if(Er)
	begin
		Q1 =R1;
		Q2 ={R2,1'b0};
		S = 33'b0;
	end
	else if(Em)
	begin
	case(Q2[1:0])
	2'b00:begin 
				Q2 = {Q2[0],Q2[16:1]};
				S = {S[32],S[32:1]};
			end
	2'b01:begin
				addres = S[32:16]+{1'b0,Q1};
				Q2 = {Q2[0],Q2[16:1]};
				addres2 = {addres,S[15:0]};
				S = {addres2[32],addres2[32:1]};
			end
	2'b10:begin
				subres = S[32:16]+{1'b1,NQ1};
				Q2 = {Q2[0],Q2[16:1]};
				subres2 = {subres,S[15:0]};
				S = {subres2[32],subres2[32:1]};
			end
	2'b11:begin 
				Q2 = {Q2[0],Q2[16:1]};
				S = {S[32],S[32:1]};
			end
	endcase
	end
	else
	begin
		Q1 = 17'b0;
		Q2 = 17'b0;
		S = 33'b0;
	end
end


assign Z = Busy ? 32'b0 : S[31:0];


endmodule
