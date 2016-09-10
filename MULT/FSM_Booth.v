`timescale 1ns / 1ps
module FSM_Booth(clk,reset,OutFSM,cont,Enable);
input clk,reset,Enable;
input[3:0] cont;
output reg [2:0] OutFSM;

reg [1:0]state,nextState;


//Asignacion asincrona de estados
always@(state,cont,Enable)
case(state)
2'b0:
	if(Enable==1) nextState = 2'b01;
	else nextState = 2'b0;
2'b01:
	nextState = 2'b10;
2'b10:
	if(cont==15) 
	begin
	nextState = 2'b0;
	end
	else nextState = 2'b10;
default: nextState = 2'b0;
endcase
//Asignacion sincrona: Actualizacion del estado
always@(posedge clk)
begin
	if(reset==1) state = 2'b0;
	else state = nextState;
end
//Asignacion de las salidas
always@(state)
	if(state==2'b00) OutFSM = 3'b000;
	else if (state==2'b01) OutFSM = 3'b110;
	else OutFSM = 3'b101;
	
endmodule 