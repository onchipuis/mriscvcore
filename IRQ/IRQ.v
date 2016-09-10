`timescale 1ns / 1ps
/////////////////////// irr = interrupción
module IRQ(
	input rst,clk,savepc,en,
	input [11:0] instr,
	input [31:0] rs1, rs2, inirr, pc, imm,
	output [31:0] rd, addrm, outirr, pc_irq, pc_c, // pc_c es el pc en dónde se estaba antes de la irr, a donde hay q volver una vez finalice la(s) irr
	output flag
    );

reg xr,s3,m7,enable,m8;
wire s1,s2,t3,t4,t5,t6,R_C;
wire [31:0] ss2,ss3,m5,mr,C_O;
reg [31:0] ss1,m1,m2,m3,m4,m6,rs1t,immt,t7,M_C,fr,q,t8,t10,rd1;
reg [8:0] t1;
assign s1 = inirr ? 1:0;
assign s2 = m1 ? 1:0;
assign ss2 = xr ? m6:m4;
assign mr = xr ? ss3:ss2;
assign m5 = m1|mr|ss2;
assign ss3 = (~ss1)&ss2;
assign t3 = rs1!=rs1t? 1:0;
assign t6 = imm!=immt? 1:0;
assign outirr=q;
assign addrm=m3;
assign flag=s3;
assign pc_c=m2;
assign pc_irq=t10;
assign rd=rd1;

always@(posedge clk or negedge rst)
	if(!rst) ss1=0;
	else if (en) ss1=rs1|imm;
	else ss1=0;

always@(posedge clk or negedge rst) // irqpc save (como salida es pc_irq)// con instrucción ojo // preguntar si esta instruccion va con en
	if(!rst) t10=0;
	else if (t1[8]) t10=rs1|imm;
	else t10=t10; 

always@(posedge clk or negedge rst) // registro para sincronización de la línea de resta de irrs
	if(!rst) m6=0;
	else if (t3|t6) m6=mr;
	else m6=m6; 
	
/*always@(negedge rst or posedge savepc) // save pc // comparar con la otra estructura y preguntar diferencia
	if(!rst) m2=0;
	else m2=pc;*/
	
// CKDUR: The above lines creates FLIP-FLOP with clock as "savepc", this is not a correc behavior
// Circuit that does the same but with FF as clk:
always@(posedge clk or negedge rst)
	if(!rst) m2=0;
	else if(savepc) m2=pc;
	else m2=m2;
	
/*	
always@(posedge clk or negedge rst or posedge s1) //pc_irq // preguntar duración minima de inirr
	if(!rst) t11=0;
	else if (s1) t11=t10;
	else t11=0;
*/

always@(posedge clk or negedge rst/* or posedge s1*/) // flag // CKDUR: not necesary to do s1 aas a latch.
	if(!rst) s3=0;
	else if(s1) s3=1;
	else if (t5) s3=0;
	else s3=s3; 
	
/*
always@(posedge clk or negedge rst) //pc_c // revisar la duración del pc_c
	if(!rst) t9=0;
	else if (t5) t9=m2;
	else t9=0;
*/

always@(negedge rst or posedge clk)
	if(!rst) m1=0;
	else if (s1|m7|m8) m1={inirr[31:2],m7,m8};
	else m1=0;

always@(posedge clk or negedge rst)
	if(!rst) m4=0;
	else m4=m5;
	
always@(negedge clk or negedge rst) // registros para detección de cambios en rs1 y imm
	if(!rst) begin rs1t=0; immt=0; end
	else if(en) begin rs1t=rs1; immt=imm; end
	else begin rs1t=rs1t; immt=immt; end 	

always@(posedge clk or negedge rst) // almacena rs1 en addrm y lo borra 
	if(!rst) m3=0;
	else if (t1[1])m3=rs1;
	else if (t1[5])m3=0;
	else m3=m3;

always@(instr,en,rst,m3,t8) // selector de instrucciones
	if(!rst) begin t1=0; rd1=0; end
	else 
	case({instr,en})
	13'b0000000110001: begin t1 = 1; rd1=0; end //SBREAK 0 
	13'b0000100110001: begin t1 = 2; rd1=0; end //ADDRMS 1 
 	13'b0001000110001: begin t1 = 4; rd1=m3; end  //ADDRME 2
	13'b0001100110001: begin t1 = 8; rd1=0; end  //TISIRR 3 
	13'b0010000110001: begin t1 = 16; rd1=t8; end  //IRRSTATE 4
	13'b0010100110001: begin t1 = 32; rd1=0; end  //CLRADDRM 5
	13'b0011000110001: begin t1 = 64; rd1=0; end  //CLRIRQ 6
	13'b0011100110001: begin t1 = 128; rd1=0; end  //RETIRQ 7
	13'b0000000110011: begin t1 = 256; rd1=0; end  //ADDPCIRQ 8
	default begin t1 = 0; rd1=0; end
	endcase
	
/*always@(negedge rst or posedge t1[6] or posedge s2) // selector del bloque que agrega y resta irrs
	if (!rst) xr=0;
	else if (s2) xr=0;
	else xr=1;*/
// CKDUR: The above lines creates FLIP-FLOP with clock as "t1[6]" or "s2", this is not a correc behavior
// THIS FLIP-FLOP ISNT EVEN SYNTHETIZABLE!!!
// Circuit that does the same but with FF as clk:
/*always@(posedge clk or negedge rst) // selector del bloque que agrega y resta irrs
	if (!rst) xr=0;
	else if (t1[6] || s2) begin 
		if (s2) xr=0;
		else xr=1;
	end*/
// CKDUR: After analisys I concluded that FF is not the behavior, this is a COMBINATIONAL.
// STILL... creates a latch in the first version. A proper way to do this CORRECTLY with "always" is like:
// Hope it works...
always@(*)
	if (!rst) xr=0;
	else if (t1[6] || s2) begin 
		if (s2) xr=0;
		else xr=1;
	end else xr=0;	// Default value

assign t4 = mr? 0:1; // indicador de alguna irr activa
assign t5= t4&t1[7]; // indicador de flag

////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst)
	if(!rst) begin enable=0; m7=0; t7=0; fr=0; M_C=0; end
	else if (t1[3])begin enable=1; m7=0; t7=0; fr=rs1; M_C=rs2; end
	else begin enable=0; m7=R_C; t7=C_O; fr=0; M_C=0; end // revisar comportamiento si en no está activado  ///

Count instance2 (
    .clk_in(clk), 
    .enable(enable), 
    .freq(fr), 
    .Max_count(M_C), 
    .RESET(!rst), 
    .Ready_count(R_C), 
    .Count_out(C_O)
    );
////////////////////////////////////////////////////////////
	
always@(negedge rst or posedge clk) // irrstate out
	if (!rst) t8=0;
	else if (t1[4]) t8=mr;
	else t8=t8;	

always@(negedge rst or posedge clk) // señal de borrado outirr
	if (!rst) q=0;
	else if (t1[6]) q=ss1&ss2;
	else q=0;

always@(negedge rst or posedge clk) // bit 0 de la interrupción - sbreak
	if (!rst) m8=0;
	else if (t1[0]) m8=1;
	else m8=0;
	
endmodule
