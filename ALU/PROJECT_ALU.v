`timescale 1 ns / 1 ps
// `default_nettype none
// `define DEBUG

`ifdef DEBUG
  `define debug(debug_command) debug_command
`else
  `define debug(debug_command)
`endif
    module ALU_PROJECT(
    
    input clk,
	input reset,
	input en, //habilita el dezplazamiento
	input [11:0] decinst,  //operacion que se desea ver a la salida (instruction decoder)
	// from Datapath
	input [31:0] rs2,
	input [31:0] inm,
	input [31:0] operando1,
	
	output reg [31:0] SALIDA_Alu,
	output reg SALIDA_comparativa,
	output reg carry,
	output reg sl_ok);
	
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
    reg [31:0] operando2;
                  
    always @(posedge clk) begin	
        if (reset) begin
               ADD_Alu <= 0;
               SUB_Alu <= 0; //colocar en c2
               
               //LOGICA COMBINACIONAL
               AND_Alu <= 0;
               XOR_Alu <= 0;    
               OR_Alu  <= 0;
               
               //COMPARACIONES
               BEQ_Alu <= 0;
               BNE_Alu <= 0;
               BGE_Alu <= 0;
               BLT_Alu <= 0;
               BGEU_Alu <= 0;
               BLTU_Alu <= 0;
               
               //DESPLAZAMIENTOS
               SRL_Alu <= 0;
               SLL_Alu <= 0;
               SRA_Alu <= 0;
		end else begin 
            //ARITMETICA
            ADD_Alu <= operando1 + operando2;
            SUB_Alu <= operando1 - operando2; //colocar en c2
            
            //LOGICA COMBINACIONAL
            AND_Alu <= operando1 & operando2;
            XOR_Alu <= operando1 ^ operando2;	
            OR_Alu  <= operando1 | operando2;
            SLT_Alu <= operando1 < operando2;
            SLTU_Alu <= $signed(operando1) < $signed(operando2);
            
            //COMPARACIONES
            BEQ_Alu <= operando1 == operando2;
            BNE_Alu <= !BEQ_Alu;
            BGE_Alu <= operando1 >= operando2;
            BLT_Alu <= !BGE_Alu;
            BGEU_Alu <= $signed(operando1) >=  $signed(operando2);
            BLTU_Alu <= !BGEU_Alu;
         end    
            if(en == 1'b1) begin
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
                end if (count ==0) begin 
                    sl_ok<=1'b1;
                end 
            end else begin
                SRL_Alu <= operando1;
                SLL_Alu <= operando1;
                SRA_Alu <= operando1;
                count <= operando2[4:0];
                sl_ok <= 0;
            end 
            
        //cero<= 0;
        //10'd0;
		//{23{1'b0}};
       
	end

	//DEFINE LA SALIDA QUE SE DESEA MOSTRAR
	always @(posedge clk) begin
		
		case (decinst)
			12'b000000010011:   begin      // addi
                                SALIDA_Alu = ADD_Alu[31:0];
                                carry = ADD_Alu[32];
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b000000110011:   begin      // add
                                SALIDA_Alu = ADD_Alu[31:0];
                                carry = ADD_Alu[32];
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end                    
			12'b100000110011:	begin //sub 
                                SALIDA_Alu = SUB_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end                    
			12'b001110010011:   begin   //andi
                                SALIDA_Alu = AND_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b001110110011:   begin   //and
                                SALIDA_Alu = AND_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
			12'b001000010011:   begin //xori
                                SALIDA_Alu = XOR_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b001000110011:   begin //xor
                                SALIDA_Alu = XOR_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end                    
			12'b001100010011:   begin //ori
                                SALIDA_Alu = OR_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b001100110011:   begin //or
                                SALIDA_Alu = OR_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
            12'b000100010011:   begin //slt pide inm
                                SALIDA_Alu = SLT_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b000110010011:   begin //sltu pide inm
                                SALIDA_Alu = SLTU_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b000100110011:   begin //slt pide rs2
                                SALIDA_Alu = SLT_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
            12'b000110110011:   begin //sltu pide rs2
                                SALIDA_Alu = SLTU_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end                    
		    12'b000001100011:   begin //beq
                                SALIDA_comparativa = BEQ_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = inm;
                                end
			12'b001011100011:   begin //bge
                                SALIDA_comparativa = BGE_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = rs2;
                                end
			12'b000011100011:   begin //bne
                                SALIDA_comparativa = BNE_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = rs2;
                                end
			12'b001001100011:   begin //blt
                                SALIDA_comparativa = BLT_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = rs2;
                                end
			12'b001101100011:   begin //bltu
                                SALIDA_comparativa = BLTU_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = rs2;
                                end
			12'b001111100011:   begin   //bgeu
                                SALIDA_comparativa = BGEU_Alu;
                                carry = 0;
                                SALIDA_Alu = 0;
                                operando2 = rs2;
                                end
		    12'b001010110011:   begin  //srl pide rs2
                                SALIDA_Alu = SRL_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
            12'b001010010011:   begin  //srl pide inm
                                SALIDA_Alu = SRL_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end                    
			12'b000010110011:   begin  //sll pide rs2
                                SALIDA_Alu = SLL_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
            12'b000010010011:   begin  //sll pide inm
                                SALIDA_Alu = SLL_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
            12'b101010110011:   begin  //sra pide rs2
                                SALIDA_Alu = SRA_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = rs2;
                                end
            12'b011010010011:   begin  //sra pide inm
                                SALIDA_Alu = SRA_Alu;
                                carry = 0;
                                SALIDA_comparativa = 0;
                                operando2 = inm;
                                end
			default:
				        SALIDA_Alu = 'b0;  //SALIDA VALDRIA CERO
				        //defaul no deja poner mas opciones? 
		endcase
	end

endmodule
