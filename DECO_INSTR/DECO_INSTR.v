`timescale 1ns / 1ps

module DECO_INSTR(
    input wire [31:0] inst,
    input wire clock,
    input wire resetDec,
    input wire enableDec,
	 //output state,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output  reg [4:0] rd,
    output reg [31:0] imm_out,
    output reg  [11:0] codif
     );

//assign inst[14:12] = inst[14:12]; 		
//REGISTRO PARA QUE COMIENCE A DECODIFICAR

	always @ (posedge clock) begin
		if (resetDec) begin
			imm_out <= {32{1'b0}};
			rd <= {5{1'b0}};
			rs1 <= {5{1'b0}};
			rs2 <= {5{1'b0}};
			//     state <= 4'b0000;
			codif <= {12{1'b0}};   //INSTRUCTION #x
		end else begin
			if (enableDec) begin
 				case (inst[6:0])
  				7'b0010111,7'b0110111: begin 				// lui, auipc
					imm_out <= {inst[31:12], {12{1'b0}}};
					rd <= inst[11:7];
					rs1 <= {5{1'b0}};
					rs2 <= {5{1'b0}};
					codif <= {{5{1'b0}} , inst[6:0]};
        		end
        		7'b1101111: begin 							// jal
					imm_out <= {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
					rd <= inst[11:7];
					rs1 <= {5{1'b0}};
					rs2 <= {5{1'b0}};
					codif <= {{5{1'b0}} , inst[6:0]}; 
        		end
				7'b1100111: begin 							// jalr
					if (inst[14:12] == 3'b000) begin 
						imm_out <= {{20{inst[31]}},inst[31:20]}; 
						rs1 <= inst[19:15];
						rd <= inst[11:7];
						rs2 <= {5{1'b0}};
						codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL: NOT jalr
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
				7'b1100011: begin 							// bXX
					if((inst[14] == 1'b1)||(inst[14:13] == 2'b00)) begin
						imm_out <= {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
						rd <= {5{1'b0}};
						rs1 <= inst[19:15];
						rs2 <= inst[24:20];
						codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL, not bXX
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end  
				7'b0000011: begin 							// lX
					if(((inst[14] == 1'b0)&&(inst[13:12] != 2'b11))||(inst[14:13] == 2'b10)) begin // lX
						imm_out <= {{20{inst[31]}},inst[31:20]}; 
						rs1 <= inst[19:15];
						rd <= inst[11:7];
						rs2 <= {5{1'b0}};
						codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL, not lX

						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
     			7'b0100011: begin 							// sX
					if((inst[14] == 1'b0)&&(inst[13:12] != 2'b11)) begin	// sX
						imm_out <= {{20{inst[31]}},inst[31:25],inst[11:7]} ;
						rs1 <= inst[19:15];
						rs2 <= inst[24:20];
						rd <= {5{1'b0}};
						codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL, not sX
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
				7'b0010011: begin // arith & logic imm
					if (inst[13:12] != 2'b01)begin // arith imm
						rd <= inst[11:7];
						rs1 <= inst[19:15];
						rs2 <= {5{1'b0}};
						imm_out <= {{20{inst[31]}},inst[31:20]}; 
						codif <= {2'b00 ,inst[14:12] , inst[6:0]};
					end else /*if (inst[13:12] == 2'b01)*/ begin // sXXi
						rd <= inst[11:7];
						rs1 <= inst[19:15];
						rs2 <= {5{1'b0}};
						imm_out <= {{20{inst[31]}},inst[31:20]}; 
						codif <= {1'b0, inst[30] ,inst[14:12] , inst[6:0]};  // Diferentiation between SRLI and SRAI is implicit on codif
					/*end else begin // ILLEGAL, not imm operations BUT LOL there is no illegal here
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};*/
					end
				end
				7'b0110011: begin // arith and logic
					if(({inst[31], inst[29:25]} == 6'b000000) || //add,sllst,sltu,xor,srl,or,and,sub,sra (inst[30] can be 1 or 0)
					   ((inst[31:25] == 7'b0000001)&&(inst[14] == 1'b0)) // mul[h[u|su]] (do not support divs)
					   ) begin 
						rs2 <= inst[24:20];
						rs1 <= inst[19:15];
						rd  <= inst[11:7];
						imm_out <= {32{1'b0}};
						codif <= {inst[30],inst[25] ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
				7'b1110011: begin // ECALL, EBREAK, CSRRX
					if(inst[14:12] != 3'b100) begin
						// Quite the same as arith imm
						rd <= inst[11:7];
						rs1 <= inst[19:15];		// WARN: This can be also zimm for CSRRX calls
						rs2 <= {5{1'b0}};
						imm_out <= {{20{1'b0}},inst[31:20]}; 
						codif <= {2'b00 ,inst[14:12] , inst[6:0]};
					end else begin// ILLEGAL
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
				7'b0011000: begin // IRQ
					if (inst[14:12] != 3'b000) begin					// IRQXX (NOT SBREAK)
						imm_out <= {{20{inst[31]}},inst[31:20]};
						rd <= {inst[11:7]};
						rs1 <= {inst[19:15]};
						rs2 <= {inst[24:20]};
						codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
					end else begin // ILLEGAL
						imm_out <= {32{1'b1}};
						rd <= {5{1'b1}};
						rs1 <={5{1'b1}};
						rs2 <= {5{1'b1}};
						codif <= {12{1'b1}};
					end
				end
				default: begin
					imm_out <= {32{1'b1}};
					rd <= {5{1'b1}};
					rs1 <={5{1'b1}};
					rs2 <= {5{1'b1}};
					codif <= {12{1'b1}};   //INSTRUCTION #x
				end
			endcase
		end
	end

endmodule
