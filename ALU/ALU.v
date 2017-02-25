`timescale 1 ns / 1 ps

module ALU #(
	parameter [ 0:0] REG_ALU = 1,
	parameter [ 0:0] REG_OUT = 1
	)
	(
    
    input clk,
	input reset,
	input en, //habilita el dezplazamiento
	input [11:0] decinst,  //operacion que se desea ver a la salida (instruction decoder)
	// from Datapath
	input [31:0] rs2,
	input [31:0] imm,
	input [31:0] rs1,
	
	output [31:0] rd,
	output reg cmp,
	output reg carry,
	output is_rd,
	output is_inst);
	
	reg [31:0] OUT_Alu;
	reg [32:0] ADD_Alu;
	reg [31:0] SUB_Alu;
	reg [31:0] AND_Alu;
	reg [31:0] XOR_Alu;
    reg [31:0] OR_Alu;
    reg [31:0] SLT_Alu;
    reg [31:0] SLTU_Alu;
    reg  BEQ_Alu;
    reg  BGE_Alu;
    reg  BNE_Alu;
    reg  BLT_Alu;
    reg  BLTU_Alu;
    reg  BGEU_Alu;
    reg [31:0] SRL_Alu;
    reg [31:0] SLL_Alu; 
    reg [31:0] SRA_Alu;
    reg [4:0]  count;
    reg [31:0] oper2;
    reg [31:0] OUT_Alu_rd;
    reg  sl_ok;
    reg [1:0] is_rd_reg;
    reg [1:0] is_inst_reg;
    reg is_rd_nr, is_inst_nr;
    
    always @(clk) begin
    	if(reset == 1'b0 || en == 1'b0) begin
    		is_rd_reg <= 0;
    		is_inst_reg <= 0;
    	end else begin
    		is_rd_reg <= {is_rd_reg[0],is_rd_nr};
    		is_inst_reg <= {is_inst_reg[0],is_inst_nr};
    	end
    end
    
    generate
		if (REG_ALU & REG_OUT) begin  
			assign is_rd = is_rd_nr & (&is_rd_reg);
			assign is_inst = is_inst_nr & (&is_inst_reg);
		end else if(REG_ALU | REG_OUT) begin
			assign is_rd = is_rd_nr & is_rd_reg[0];
			assign is_inst = is_inst_nr & is_inst_reg[0];
		end else begin
			assign is_rd = is_rd_nr;
			assign is_inst = is_inst_nr;
		end
	endgenerate
    
    // WORKAROUND ABOUT 'oper2' and 'rd enable'
	always @* begin
		is_rd_nr = en;
		is_inst_nr = en;
		case (decinst)
			12'b000000010011:   begin // addi
                                oper2 = imm;
                                end
            12'b000000110011:   begin // add
                                oper2 = rs2;
                                end                    
			12'b100000110011:	begin //sub 
                                oper2 = rs2;
                                end                    
			12'b001110010011:   begin //andi
                                oper2 = imm;
                                end
            12'b001110110011:   begin //and
                                oper2 = rs2;
                                end
			12'b001000010011:   begin //xori
                                oper2 = imm;
                                end
            12'b001000110011:   begin //xor
                                oper2 = rs2;
                                end                    
			12'b001100010011:   begin //ori
                                oper2 = imm;
                                end
            12'b001100110011:   begin //or
                                oper2 = rs2;
                                end
            12'b000100010011:   begin //slti
                                oper2 = imm;
                                end
            12'b000110010011:   begin //sltiu
                                oper2 = imm;
                                end
            12'b000100110011:   begin //slt
                                oper2 = rs2;
                                end
            12'b000110110011:   begin //sltu
                                oper2 = rs2;
                                end                    
		    12'b000001100011:   begin //beq
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
			12'b001011100011:   begin //bge
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
			12'b000011100011:   begin //bne
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
			12'b001001100011:   begin //blt
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
			12'b001101100011:   begin //bltu
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
			12'b001111100011:   begin //bgeu
                                oper2 = rs2;
                                is_rd_nr = 1'b0;
                                end
		    12'b001010110011:   begin //srl
                                oper2 = rs2;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end
            12'b001010010011:   begin //srli
                                oper2 = imm;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end                    
			12'b000010110011:   begin //sll
                                oper2 = rs2;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end
            12'b000010010011:   begin //slli
                                oper2 = imm;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end
            12'b101010110011:   begin //sra
                                oper2 = rs2;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end
            12'b011010010011:   begin //srai
                                oper2 = imm;
                                is_rd_nr = sl_ok;
                                is_inst_nr = sl_ok;
                                end
			default:			begin // NO INSTRUCTION
                                oper2 = 'bx;
                                is_rd_nr = 1'b0;
                                is_inst_nr = 1'b0;
                                end
		endcase
	end
	
	// ALU
    generate 
		if (REG_ALU) begin            
			always @(posedge clk) begin	
				if (!reset) begin
				    // ARITH
					ADD_Alu <= 0;
					SUB_Alu <= 0;

					// COMBINATIONAL
					AND_Alu <= 0;
					XOR_Alu <= 0;    
					OR_Alu  <= 0;
				end else begin 
				    // ARITH
				    ADD_Alu <= rs1 + oper2;
				    SUB_Alu <= rs1 - oper2; 
				    
				    // COMBINATIONAL
				    AND_Alu <= rs1 & oper2;
				    XOR_Alu <= rs1 ^ oper2;	
				    OR_Alu  <= rs1 | oper2;
				    SLT_Alu <= $signed(rs1) < $signed(oper2);
				    SLTU_Alu <= rs1 < oper2;
				end
			end
			always @* begin	 
				// COMPARE
				BEQ_Alu = rs1 == oper2;
				BNE_Alu = !BEQ_Alu;
				BGE_Alu = $signed(rs1) >= $signed(oper2);
				BLT_Alu = !BGE_Alu;
				BGEU_Alu = rs1 >=  oper2;
				BLTU_Alu = !BGEU_Alu;
			end
		end else begin
			always @* begin	 
				// ARITH
				ADD_Alu = rs1 + oper2;
				SUB_Alu = rs1 - oper2; 
				
				// COMBINATIONAL
				AND_Alu = rs1 & oper2;
				XOR_Alu = rs1 ^ oper2;	
				OR_Alu  = rs1 | oper2;
				SLT_Alu = $signed(rs1) < $signed(oper2);
				SLTU_Alu = rs1 < oper2;
				
				// COMPARE
				BEQ_Alu = rs1 == oper2;
				BNE_Alu = !BEQ_Alu;
				BLT_Alu = $signed(rs1) < $signed(oper2);
				BGE_Alu = !BLT_Alu;
				BLTU_Alu = rs1 < oper2;
				BGEU_Alu = !BLTU_Alu;
			end
		end
	endgenerate
	
	
	
	// SHIFTS
	always @(posedge clk) begin	
		if (!reset) begin
			SRL_Alu <= 0;
			SLL_Alu <= 0;
			SRA_Alu <= 0;
			count <= 0;
		end else if(en == 1'b1) begin
            if(count >= 5'd4) begin
                SRL_Alu <= SRL_Alu >> 4;
                SLL_Alu <= SLL_Alu << 4;
                SRA_Alu <= $signed(SRA_Alu) >>> 4;
                //SRA_Alu <= {4{SRA_Alu[31]},SRA_Alu[31:4]};
                count <= count - 4;
            end else if(count != 5'd0) begin
                SRL_Alu <= SRL_Alu >> 1;
                SLL_Alu <= SLL_Alu << 1;
                SRA_Alu <= $signed(SRA_Alu) >>> 1;
                count <= count - 1;
            end else if (count ==0) begin 
                sl_ok<=1'b1;
            end 
        end else begin
            SRL_Alu <= rs1;
            SLL_Alu <= rs1;
            SRA_Alu <= rs1;
            count <= oper2[4:0];
            sl_ok <= 0;
        end 
	end

	// DEFINE FINAL OUTPUT
	always @* begin
		
		case (decinst)
			12'b000000010011:   begin      // addi
                                OUT_Alu = ADD_Alu[31:0];
                                carry = ADD_Alu[32];
                                cmp = 0;
                                end
            12'b000000110011:   begin      // add
                                OUT_Alu = ADD_Alu[31:0];
                                carry = ADD_Alu[32];
                                cmp = 0;
                                end                    
			12'b100000110011:	begin //sub 
                                OUT_Alu = SUB_Alu;
                                carry = 0;
                                cmp = 0;
                                end                    
			12'b001110010011:   begin   //andi
                                OUT_Alu = AND_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b001110110011:   begin   //and
                                OUT_Alu = AND_Alu;
                                carry = 0;
                                cmp = 0;
                                end
			12'b001000010011:   begin //xori
                                OUT_Alu = XOR_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b001000110011:   begin //xor
                                OUT_Alu = XOR_Alu;
                                carry = 0;
                                cmp = 0;
                                end                    
			12'b001100010011:   begin //ori
                                OUT_Alu = OR_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b001100110011:   begin //or
                                OUT_Alu = OR_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b000100010011:   begin //slt pide imm
                                OUT_Alu = SLT_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b000110010011:   begin //sltu pide imm
                                OUT_Alu = SLTU_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b000100110011:   begin //slt pide rs2
                                OUT_Alu = SLT_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b000110110011:   begin //sltu pide rs2
                                OUT_Alu = SLTU_Alu;
                                carry = 0;
                                cmp = 0;
                                end                    
		    12'b000001100011:   begin //beq
                                cmp = BEQ_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
			12'b001011100011:   begin //bge
                                cmp = BGE_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
			12'b000011100011:   begin //bne
                                cmp = BNE_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
			12'b001001100011:   begin //blt
                                cmp = BLT_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
			12'b001101100011:   begin //bltu
                                cmp = BLTU_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
			12'b001111100011:   begin   //bgeu
                                cmp = BGEU_Alu;
                                carry = 0;
                                OUT_Alu = 0;
                                end
		    12'b001010110011:   begin  //srl pide rs2
                                OUT_Alu = SRL_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b001010010011:   begin  //srl pide imm
                                OUT_Alu = SRL_Alu;
                                carry = 0;
                                cmp = 0;
                                end                    
			12'b000010110011:   begin  //sll pide rs2
                                OUT_Alu = SLL_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b000010010011:   begin  //sll pide imm
                                OUT_Alu = SLL_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b101010110011:   begin  //sra pide rs2
                                OUT_Alu = SRA_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            12'b011010010011:   begin  //sra pide imm
                                OUT_Alu = SRA_Alu;
                                carry = 0;
                                cmp = 0;
                                end
            // NO DEFAULT ACTION
		endcase
	end
	
	generate 
		if (REG_ALU) begin            
			always @(posedge clk) begin	
				if (!reset) begin
					OUT_Alu_rd <= 0;
				end else begin
					OUT_Alu_rd <= OUT_Alu; 
				end
			end
		end else begin
			always @* begin	
				OUT_Alu_rd = OUT_Alu; 
			end
		end
	endgenerate
	
	assign rd = is_rd_nr?OUT_Alu_rd:32'bz;
	

endmodule
