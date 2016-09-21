`timescale 1ns / 1ps

module Sim_DecInstru1;

	// Inputs
	reg [31:0] inst;
	reg clock;
	reg resetDec;
	reg enableDec;

	// Outputs
	wire [4:0] rs1;
	wire [4:0] rs2;
	wire [4:0] rd;
	wire [31:0] imm_out;
	wire [11:0] codif;
//	wire state;

	// Instantiate the Unit Under Test (UUT)
	DECO_INSTR uut (
		.inst(inst), 
		.clock(clock),
		.resetDec(resetDec),
		.enableDec(enableDec),
		.rs1(rs1), 
		.rs2(rs2), 
		.rd(rd), 
		.imm_out(imm_out), 
		.codif(codif)
//		.state(state)
	);




	initial begin
		// Initialize Inputs
	//	always
clock=0;
//#40;

//INSTRUCCIÓN AUIPC, RESET
inst = 32'b00001111000011110000111100010111;
resetDec=1;  
enableDec=0;                                                                                       
#20;
//INSTRUCCIÓN AUIPC (#1)
inst = 32'b00001111000011110000111100010111;
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN lui (#2)

inst = 32'b00001111000011110000111100110111;
resetDec=0; 
enableDec=1;                                                                                           
#20;


//INSTRUCCIÓN JAL (#3) funcional
inst = 32'b00001111000011110000111101101111;
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN JAL (#3) reset desactivado y enable desactivado
inst = 32'b00001111000011110000111101101111;
resetDec=0;
enableDec=0; 
#20
//INSTRUCCIÓN JAL (#3) reset activado y enable activado
inst = 32'b00001111000011110000111101101111;
resetDec=1;
enableDec=1; 
#20
//INSTRUCCIÓN JAL (#3) reset desactivado y enable desactivado
inst = 32'b00001111000011110000111101101111;
resetDec=0;
enableDec=0; 
#20

//Instrucción BEQ (#4)
inst = {7'b1010101,5'b00011,5'b00110,3'b000,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción BNE (#5)
inst = {7'b1010101,5'b00011,5'b00110,3'b001,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20

//Instrucción BLT (#6)
inst = {7'b1010101,5'b00011,5'b00110,3'b100,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción BGE (#7)
inst = {7'b1010101,5'b00011,5'b00110,3'b101,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción BLTU (#8)
inst = {7'b1010101,5'b00011,5'b00110,3'b110,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción BGEU (#9)
inst = {7'b1010101,5'b00011,5'b00110,3'b111,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SB (#10)
inst = {7'b1010101,5'b00011,5'b00110,3'b000,5'b11011,7'b0100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SH (#11)
inst = {7'b1010101,5'b00011,5'b00110,3'b001,5'b11011,7'b0100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SW (#12)
inst = {7'b1010101,5'b00011,5'b00110,3'b010,5'b11011,7'b0100011};
resetDec=0;
enableDec=1; 
#20

//Instrucción LB (#13)
inst = {7'b1010101,5'b00011,5'b00110,3'b000,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20
//Instrucción LH (#14)
inst = {7'b1010101,5'b00011,5'b00110,3'b001,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20
//Instrucción LW (#15)
inst = {7'b1010101,5'b00011,5'b00110,3'b010,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20
//Instrucción LBU (#16)
inst = {7'b1010101,5'b00011,5'b00110,3'b100,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20
//Instrucción LHU (#17)
inst = {7'b1010101,5'b00011,5'b00110,3'b101,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20

//Instrucción ADDI (#18)
inst = {7'b1010101,5'b00011,5'b00110,3'b000,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SLTI (#19)
inst = {7'b1010101,5'b00011,5'b00110,3'b010,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción sltiu (#20)
inst = {7'b1010101,5'b00011,5'b00110,3'b011,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción XORI (#21)
inst = {7'b1010101,5'b00011,5'b00110,3'b100,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción ORI (#22)
inst = {7'b1010101,5'b00011,5'b00110,3'b110,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción ANDI (#23)
inst = {7'b1010101,5'b00011,5'b00110,3'b111,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SLLI (#24)
inst = {7'b0000000,5'b00011,5'b00110,3'b001,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SRLI (#25)
inst = {7'b0000000,5'b00011,5'b00110,3'b101,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción SRAI (#26)
inst = {7'b0100000,5'b00011,5'b00110,3'b101,5'b11011,7'b0010011};
resetDec=0;
enableDec=1; 
#20
//Instrucción JALR (#27)
inst = {17'b010000000011,5'b00100,3'b000,5'b11011,7'b1100111};
resetDec=0;
enableDec=1; 
#20


//INSTRUCCIÓN add (#28)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b000, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN sub (#29)
inst = {2'b01,{5{1'b0}},5'b11001,5'b11001,3'b000, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN sll (#30)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b001, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN slt (#31)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b010, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN sltu (#32)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b011, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN xor (#33)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b100, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN srl (#34)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b101, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN sra (#35)
inst = {2'b01,{5{1'b0}},5'b11001,5'b11001,3'b101, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN or (#36)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b110, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN and (#37)
inst = {2'b00,{5{1'b0}},5'b11001,5'b11001,3'b111, 5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20

//IRQ
//INSTRUCCIÓN SBREAK (#38)
inst = {{11{1'b0}},1'b1,{13{1'b0}},7'b0011000};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN ADDRMS (#39) rs1=00100
inst = {{12{1'b0}},5'b00100,3'b001,5'b00000,7'b0011000};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN ADDRME (#40) 
inst = {{17{1'b0}},3'b010,5'b00100,7'b0011000};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN TISIRR (#41) rs1=00100
inst = {{7{1'b0}},5'b00100,5'b00100,3'b011,5'b00000,7'b0011000};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN IRRSTATE (#42) 
inst = {{17{1'b0}},3'b100,5'b00100,7'b0011000};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN clraddrm (#43) 
inst = {{17{1'b0}},3'b101,5'b00000,7'b0011000};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN CLRIRQ (#44)
inst = {12'b101010101010,5'b00100,3'b110, 5'b00000,7'b0011000};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN RETIRQ (#45) 
inst = {{17{1'b0}},3'b111,5'b00000,7'b0011000};
resetDec=0;
enableDec=1; 
#20

//MULTIPLICADOR
//INSTRUCCIÓN MUL (#46)
inst = {{6{1'b0}},1'b1,5'b00011,5'b00110,3'b000,5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN MULH (#47)
inst = {{6{1'b0}},1'b1,5'b00011,5'b00110,3'b001,5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN MULHSU (#48)
inst = {{6{1'b0}},1'b1,5'b00011,5'b00110,3'b010,5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN MULHU (#49)
inst = {{6{1'b0}},1'b1,5'b00011,5'b00110,3'b011,5'b11001,7'b0110011};
resetDec=0;
enableDec=1; 
#20


//INSTRUCCIONES INVÁLIDAS
//Instrucción tipo sb inválida 5,6
inst = {7'b1010101,5'b00011,5'b00110,3'b010,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción tipo sb inválida
inst = {7'b1010101,5'b00011,5'b00110,3'b011,5'b11011,7'b1100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción Inválida tipo s
inst = {7'b1010101,5'b00011,5'b00110,3'b100,5'b11011,7'b0100011};
resetDec=0;
enableDec=1; 
#20
//Instrucción TIPO i inválida 17
inst = {7'b1010101,5'b00011,5'b00110,3'b111,5'b11011,7'b0000011};
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN 24-26 (INVÁLIDA)
inst = 32'b00001111000011110001111100010011;
resetDec=0;
enableDec=1; 
#20

//INSTRUCCIÓN 28-37 (NO CUMPLE)
inst = 32'b00001111000011110000111100110011;
resetDec=0;
enableDec=1; 
#20


//UNA INSTRUCCIÓN Parecida IRQ (Inválida)
inst = 32'b00001111000011110000111100011000;
resetDec=0;
enableDec=1; 
#20


//UNA INSTRUCCIÓN DEL MULTIPLIPLICADOR (Inválida)
inst = 32'b00000011010101010110001100110011;
resetDec=0;
enableDec=1; 
#20


//UNA INSTRUCCIÓN DEL MULTIPLIPLICADOR (Inválida)
inst = 32'b00001111000011110000111100110011;
resetDec=0;
enableDec=1; 
#20
//INSTRUCCIÓN DIFERENTE A LAS CODIFICADAS (opcode distinto)
inst = 32'b10001111000011110000111100110011;
resetDec=0;
enableDec=1; 
#20



//INSTRUCCIÓN DIFERENTE A LAS CODIFICADAS2 (opcode distinto)
inst = 32'b00001111000011110000111111111111;
resetDec=0;
enableDec=1; 
		
		// Wait 100 ns for global reset to finish
	//	#100;
        
		// Add stimulus here
end

always #5 clock=~clock;   
endmodule
