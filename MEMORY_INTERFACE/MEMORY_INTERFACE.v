`timescale 1ns / 1ps

module MEMORY_INTERFACE(
    input clock,
    input resetn,
    input [31:0] rs1,
    input [31:0] rs2,
	input [31:0] Rdata_mem,
    input ARready,
	input Rvalid,
	input AWready,
	input Wready,
	input Bvalid,
	input [31:0] imm, 
    input [1:0] W_R,
    input [1:0] wordsize,
    input enable,
	input [31:0] pc,
	input signo,
	
	output reg busy, 
	output reg done,
	output reg alineado, 
	output reg [31:0] AWdata,
	output reg [31:0] ARdata,
	output reg [31:0] Wdata,
	output [31:0] rd,inst,
	output reg ARvalid,
	output reg RReady,
	output reg AWvalid,
	output reg Wvalid,
	output reg [2:0] arprot,awprot,
	output reg Bready,
	output reg [3:0] Wstrb,
	output reg rd_en
	//output reg [3:0] Rstrb
	);
	
	
	reg [7:0] relleno8;
	reg [15:0] relleno16;
	reg [31:0] Rdataq,Wdataq;
	reg [3:0] Wstrbq;
	reg [31:0] rdu,minstr,minstru;
	reg rd_en,en_instr;
///////////////////////////////////////////////////////////////////////////////////
/////////////// BEGIN FSM
//////////////////////////////////////////////////////////////////////////////////	
	reg [2:0]state,nexstate;
	reg [6:0]salida;

	parameter reposo 	= 3'b000;
	parameter inicioR 	= 3'b001;
	parameter SR 		= 3'b010;
	parameter inicioW 	= 3'b011;
	parameter SW1 		= 3'b100;
	parameter SW2		= 3'b101;
	
	// Instantiate the module
	always @(state,ARready,W_R,Rvalid,AWready,Wready,Bvalid,enable) begin
		case (state)
			reposo : begin
				if ((W_R==2'b11 && enable==1)|| (W_R==2'b01 && enable==1)) begin
					nexstate = inicioR;
				end else if (W_R==2'b00 && enable==1) begin
					nexstate = inicioW;
				end else begin
					nexstate = reposo;
				end
			end

			inicioR : begin
				if(ARready) begin
					nexstate = SR;
				end else begin
					nexstate=inicioR;
				end
			end

			SR : begin
				if(Rvalid) begin
					nexstate = reposo;
				end else begin
					nexstate=SR;
				end
			end

			inicioW : begin
				if (AWready) begin
					nexstate = SW1;
				end else begin
					nexstate = inicioW;
				end
			end

			SW1 : begin
				if (Wready) begin
					nexstate=SW2;
				end else begin
					nexstate=SW1;
				end
			end
			
			SW2 : begin
				if (Bvalid) begin
					nexstate=reposo;
				end else begin
					nexstate=SW2;
				end
			end

			default : begin  // Fault Recovery
				nexstate = reposo;
			end   
		endcase
	end

    // Sync assign
    always @(posedge clock)
        if(resetn == 0) state <= reposo;
        else state <= nexstate;
    
    // Output assign
    always @(state) begin
        if (state==reposo)
            salida=7'b0000001;
        else if (state==inicioR)
            salida=7'b1100010;
        else if (state==SR)
            salida=7'b1100010;
        else if (state==inicioW)
            salida=7'b0010010;
        else if (state==SW1)
            salida=7'b0001010;
        else if (state==SW2)
            salida=7'b0001110;
        else
            salida=7'bxxxxxxx;
    end
    
    always @(salida) begin
        ARvalid	= salida[6];
        RReady 	= salida[5];
        AWvalid	= salida[4];
        Wvalid	= salida[3];
        Bready	= salida[2];
        busy	= salida[1];
        done	= salida[0];
        
    end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////	
////////////////////// END FSM
///////////////////////////////////////////////////////////////////////////////////////////
    
	always @* begin
		// Default values
		en_instr 	= 0;
		rd_en 		= 0;
		awprot 		= 3'b000;
		AWdata		= rs1+imm;
		arprot		= 3'b000;
		ARdata		= rs2+imm;
		alineado 	= 0;
		Wdataq		= 0;
		Wstrbq		= 4'b0000;
		minstru		= 0;
		Rdataq		= 0;
		relleno8	= 0;
		relleno16	= 0;
		
		case (W_R)
			2'b00  : begin
				en_instr = 0;
				rd_en = 0;
				awprot = 3'b000;
				AWdata = rs1+imm;
				case (wordsize)
					2'b10  : begin
						alineado=(AWdata[1:0]==2'b00)? 1:0;
						Wdataq=rs1;
						Wstrbq=4'b1111;
					end
					2'b01  : begin
						alineado=(AWdata[0]==1'b0)? 1:0;
						Wstrbq = AWdata[1] ? 4'b1100 : 4'b0011;
						Wdataq={2{rs1[15:0]}};
					end
					2'b00  : begin
						alineado=1;
						Wstrbq = 4'b0001 << ARdata[1:0];
						Wdataq={4{rs1[7:0]}};
					end
				endcase						
			end

			2'b10,2'b11  : begin
				rd_en=0;
				en_instr=1;
				minstru=Rdata_mem;
				AWdata=pc;
				ARdata=pc;
				arprot=3'b100;
			end

			2'b01 : begin
				rd_en=1;
				arprot=3'b000;
				en_instr=0;
				ARdata= rs2+imm;
				case (wordsize)
					2'b10  : begin
						alineado=(ARdata[1:0]==0)? 1:0;
						Rdataq=Rdata_mem;
					end
					
					2'b01  : begin
						alineado=(ARdata[0]==0)? 1:0;
						case (ARdata[1])
							1'b0: begin 
								case (signo) 
									1'b1: relleno8={16{Rdata_mem[15]}};
									1'b0: relleno8=16'd0;
								endcase
								Rdataq= {relleno8,Rdata_mem[15:0]};
							end
							1'b1: begin 
								case (signo) 
									1'b1: relleno8={16{Rdata_mem[31]}};
									1'b0: relleno8=16'd0;
								endcase
								Rdataq = {relleno8,Rdata_mem[31:16]};
							end
						endcase
					end
			
					2'b00  : begin
						alineado=1;
						case (ARdata[1:0])
							2'b00:  begin 
								case (signo) 
									1'b0: relleno16=24'd0;
									1'b1: relleno16={24{Rdata_mem[7]}};
								endcase
								Rdataq = {relleno16,Rdata_mem[ 7: 0]}; 
							end
							2'b01:  begin 
								case (signo) 
									1'b0: relleno16=24'd0;
									1'b1: relleno16={24{Rdata_mem[15]}};
								endcase 
								Rdataq = {relleno16,Rdata_mem[15: 8]}; 
							end
							2'b10:  begin 
								case (signo) 
									1'b0: relleno16=24'd0;
									1'b1: relleno16={24{Rdata_mem[23]}};
								endcase
								Rdataq = {relleno16,Rdata_mem[23:16]}; 
							end
							2'b11:  begin 
								case (signo) 
									1'b0: relleno16=24'd0;
									1'b1: relleno16={24{Rdata_mem[31]}};
								endcase 
								Rdataq = {relleno16,Rdata_mem[31:24]}; 
							end
						endcase
					end
				endcase	
			end
		endcase
	end
	

	always @ (posedge clock) begin
		if (!resetn) begin
			Wdata <= 32'd0;
			rdu <= 32'd0;
			Wstrb <= 4'b0000;
			minstr<=32'd0;
				 
		end else begin 
			Wdata<=Wdataq;
			rdu<=Rdataq;
			Wstrb<=Wstrbq;
			if(en_instr) minstr<=minstru;
		end
    end
	
    assign rd=rd_en ?rdu :32'bz ;
	assign inst=minstr;
		 

endmodule

