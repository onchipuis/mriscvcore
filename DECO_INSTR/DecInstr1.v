`timescale 1ns / 1ps

module DecInstr1(
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

always @ (posedge clock or posedge resetDec)
if (resetDec)
  begin
                imm_out <= {32{1'b0}};
                   rd <= {5{1'b0}};
                    rs1 <= {5{1'b0}};
                  rs2 <= {5{1'b0}};
                //     state <= 4'b0000;
                 codif <= {12{1'b0}};   //INSTRUCCIÓN #x
                 end


//decode
else //if (clock)//(modificar)
//begin  //(ADDED)
if (enableDec)
begin
 case (inst[6:0])
  7'b0010111: 
     //auipc	
   begin
        //En este caso se agregan ceros a la derecha
        imm_out <= {inst[31:12], {12{1'b0}}};
        rd <= inst[11:7];
        rs1 <= {5{1'b0}};
        rs2 <= {5{1'b0}};
        codif <= {{5{1'b0}} , inst[6:0]};   //INSTRUCCIÓN #1
        end
     
  7'b0110111: 
  //lui
   begin
        imm_out <= {inst[31:12], {12{1'b0}}};
        rd <= inst[11:7];
        rs1 <= {5{1'b0}};
        rs2 <= {5{1'b0}};
        codif <= {{5{1'b0}} , inst[6:0]};   //INSTRUCCIÓN #2
        end   
  
     
  7'b1101111: 
     //jal
   begin
          //Se expande MSB hacia la izq de imm
        imm_out <= {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
        rd <= inst[11:7];
        rs1 <= {5{1'b0}};
        rs2 <= {5{1'b0}};
        codif <= {{5{1'b0}} , inst[6:0]};   //INSTRUCCIÓN #3
        end
      
  7'b1100011: 
  begin
  if((inst[14:12] == 3'b000)||(inst[14:12] == 3'b001)||(inst[14:12] == 3'b100)||(inst[14:12] == 3'b101)||(inst[14:12] == 3'b110)||(inst[14:12] == 3'b111)) begin
               //Se expande MSB hacia la izq de imm
        imm_out <= {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
        rd <= {5{1'b0}};
        rs1 <= inst[19:15];
        rs2 <= inst[24:20];
        codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};   //INSTRUCCIÓN #4 (beq)
        end
   else
      begin
       imm_out <= {32{1'b1}};
       rd <= {5{1'b1}};
       rs1 <={5{1'b1}};
       rs2 <= {5{1'b1}};
       codif <= {12{1'b1}};
      end
   end  
     
     
  7'b0100011 :      //tipo s           //Se expande MSB hacia la izq de imm    
  begin
  if((inst[14:12] == 3'b000)||(inst[14:12] == 3'b001)||(inst[14:12] == 3'b010)) begin
        imm_out <= {{20{inst[31]}},inst[31:25],inst[11:7]} ;
        rs1 <= inst[19:15];
        rs2 <= inst[24:20];
        rd <= {5{1'b0}};
        codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
        end
   else 
       begin
          imm_out <= {32{1'b1}};
          rd <= {5{1'b1}};
          rs1 <={5{1'b1}};
          rs2 <= {5{1'b1}};
          codif <= {12{1'b1}};
          end
      end
     
     7'b0000011 :
       begin           //Se expande MSB hacia la izq de imm
       if((inst[14:12] == 3'b000)||(inst[14:12] == 3'b001)||(inst[14:12] == 3'b010)||(inst[14:12] == 3'b100)||(inst[14:12] == 3'b101)) begin

           imm_out <= {{20{inst[31]}},inst[31:20]}; 
           rs1 <= inst[19:15];
           rd <= inst[11:7];
           rs2 <= {5{1'b0}};
           codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};   //INSTRUCCIÓN #27 (jalr)
           end
       else
       begin
               imm_out <= {32{1'b1}};
               rd <= {5{1'b1}};
               rs1 <={5{1'b1}};
               rs2 <= {5{1'b1}};
               codif <= {12{1'b1}};
               end
        end
       
        
     
     
  7'b1100111: // jalr
   begin
   if (inst[14:12] == 3'b000) begin           //Se expande MSB hacia la izq de imm
        imm_out <= {{20{inst[31]}},inst[31:20]}; 
        rs1 <= inst[19:15];
        rd <= inst[11:7];
        rs2 <= {5{1'b0}};
        codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};   //INSTRUCCIÓN #27 (jalr)
        end
     else
     begin
        imm_out <= {32{1'b1}};
        rd <= {5{1'b1}};
        rs1 <={5{1'b1}};
        rs2 <= {5{1'b1}};
        codif <= {12{1'b1}};
        end
     end
     
     
  7'b0010011   : 
     //tipo i 
       
   begin
        //SLLI,SRLI,SRAI
        if ((inst[31:25] == 7'b0000000)&&((inst[14:12] == 3'b001)||(inst[14:12] == 3'b101)))begin
        //shamt    
        rd <= inst[11:7];
        rs1 <= inst[19:15];
        rs2 <= {5{1'b0}};
        imm_out <= {{20{inst[31]}},inst[31:20]}; 
        codif <= {1'b0, inst[30] ,inst[14:12] , inst[6:0]}; 
        end
        else
        if ((inst[31:25] == 7'b0100000)&&(inst[14:12] == 3'b101))begin
        rd <= inst[11:7];
        rs1 <= inst[19:15];
        rs2 <= {5{1'b0}};
        imm_out <= {{20{inst[31]}},inst[31:20]}; 
        codif <= {1'b0, inst[30] ,inst[14:12] , inst[6:0]}; 
        end
        else
        if ((inst[14:12] == 3'b000)||(inst[14:12] == 3'b010)||(inst[14:12] == 3'b011)||(inst[14:12] == 3'b100)||(inst[14:12] == 3'b110)||(inst[14:12] == 3'b111))begin
        rd <= inst[11:7];
        rs1 <= inst[19:15];
        rs2 <= {5{1'b0}};
        imm_out <= {{20{inst[31]}},inst[31:20]}; 
        codif <= {{2{1'b0}},inst[14:12] , inst[6:0]}; 
        end
        else
        begin
        imm_out <= {32{1'b1}};
        rd <= {5{1'b1}};
        rs1 <={5{1'b1}};
        rs2 <= {5{1'b1}};
        codif <= {12{1'b1}};
        end
        end
     
      
  7'b0110011   : 
     //tipo r y Multiplicador
     
     
   begin
        //add,sllst,sltu,xor,srl,or,and
        if(inst[31:25] == 7'b0000000) begin
        rs2 <= inst[24:20];
        rs1 <= inst[19:15];
        rd  <= inst[11:7];
        imm_out <= {32{1'b0}};
        codif <= {inst[30],inst[25] ,inst[14:12] , inst[6:0]};
        end
        //sub y sra
        else
        if((inst[31:25] == 7'b0100000)&&((inst[14:12] == 3'b000)||(inst[14:12] == 3'b101)))  begin
        rs2 <= inst[24:20];
        rs1 <= inst[19:15];
        rd  <= inst[11:7];
        imm_out <= {32{1'b0}};
        codif <= {inst[30],inst[25] ,inst[14:12] , inst[6:0]};
        end
        else
        //multiplicador
        if((inst[31:25] == 7'b0000001)&&((inst[14:12] == 3'b000)||(inst[14:12] == 3'b001)||(inst[14:12] == 3'b010)||(inst[14:12] == 3'b011)))  begin
        //if(inst[31:25] == 7'b0000001)  begin
        rs2 <= inst[24:20];
        rs1 <= inst[19:15];
        rd  <= inst[11:7];
        imm_out <= {32{1'b0}};
        codif <= {inst[30],inst[25] ,inst[14:12] , inst[6:0]};
        end
        
        //instruccion extraña
        else
        begin
        imm_out <= {32{1'b1}};
        rd <= {5{1'b1}};
        rs1 <={5{1'b1}};
        rs2 <= {5{1'b1}};
        codif <= {12{1'b1}};
        end
        end
        
  
        

  7'b1110011   : //sbreak (especial)
     //tipo i
     
   begin
        imm_out <= {{31{1'b0}},1'b1}; 
        rs1 <= {5{1'b0}};
        rd <= {3{1'b0}};
        rs2 <= {5{1'b0}};
        codif <= {{5{1'b0}} , inst[6:0]};
        end
  
  //INSTRUCCIONES DEL IRQ
  
  7'b0011000:
  begin
  //begin
  if ((inst[19:7] == {13{1'b0}}) &&(inst[31:20] == 12'b000000000001) ) 
  begin
  //imm_out <= {{31{1'b0}} ,1'b1};
  imm_out <= {{31{1'b0}},1'b1};
  rd <= {5{1'b0}};
  rs1 <= {5{1'b0}};
  rs2 <= {5{1'b0}};
  codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  
  else
  if ((inst[14:12] == 3'b001) &&(inst[31:20] == {12{1'b0}})&&(inst[11:7] == {5{1'b0}}))
   begin
   imm_out <= {32{1'b0}};
   rd <= {5{1'b0}};
   rs1 <= {inst[19:15]};
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
   end
   else
  //
  if ((inst[14:12] == 3'b010) &&(inst[31:20] == {12{1'b0}}))
  begin
  imm_out <= {32{1'b0}};
  rd <=  {inst[11:7]};
  rs1 <= {5{1'b0}};
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  //rev
  else
   if ((inst[14:12] == 3'b011) &&(inst[31:25] == {7{1'b0}})&&(inst[11:7] == {5{1'b0}}))
  begin
  imm_out <= {32{1'b0}};
  rd <=  {5{1'b0}};
  rs1 <= {inst[19:15]};
  rs2 <= {inst[24:20]};
  codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  else
   if ((inst[14:12] == 3'b100)&&(inst[31:15] == {17{1'b0}}))
  begin
  imm_out <= {32{1'b0}};
  rd <=  {inst[11:7]};
  rs1 <= {5{1'b0}};
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  else
   if ((inst[14:12] == 3'b101)&&(inst[31:15] == {17{1'b0}})&&(inst[11:7] == {5{1'b0}}))
  begin
  imm_out <= {32{1'b0}};
  rd <=  {5{1'b0}};
  rs1 <= {5{1'b0}};
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  else
  if ((inst[14:12] == 3'b110) &&(inst[11:7] == {5{1'b0}}))
  begin
  //Expandiendo MSB en imm
  imm_out <= {{20{inst[31]}},inst[31:20]};
  rd <=  {5{1'b0}};
  rs1 <= inst[19:15];
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end
  else
   if ((inst[14:12] == 3'b111) &&(inst[31:15] == {17{1'b0}})&&(inst[11:7] == {5{1'b0}}))
  begin
  imm_out <= {32{1'b0}};
  rd <=  {5{1'b0}};
  rs1 <= {5{1'b0}};
   rs2 <= {5{1'b0}};
   codif <= {{2{1'b0}} ,inst[14:12] , inst[6:0]};
  end 
  
   else
   //instrucción extraña
      begin
         imm_out <= {32{1'b1}};
         rd <= {5{1'b1}};
         rs1 <={5{1'b1}};
         rs2 <= {5{1'b1}};
         codif <= {12{1'b1}};
         end
     end
  //   
default: 
   begin
        imm_out <= {32{1'b1}};
        rd <= {5{1'b1}};
        rs1 <={5{1'b1}};
        rs2 <= {5{1'b1}};
        codif <= {12{1'b1}};   //INSTRUCCIÓN #x
        end   
 endcase
 end
//end //(added)
endmodule