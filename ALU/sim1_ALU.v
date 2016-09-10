`timescale 1ns / 1ps

module sim1;
    
   reg clk;
   reg reset;
   reg en;
   reg [11:0] decinst; 
   reg [31:0] operando1;
   reg [31:0] rs2;
   reg [31:0] inm;
   
   wire [31:0] SALIDA_Alu;
   wire SALIDA_comparativa; 
   wire carry;
   wire sl_ok;
    
  ALU_PROJECT uut (
           .clk(clk), 
           .reset(reset),
           .decinst(decinst),
           .en(en), 
           .operando1(operando1), 
           .rs2(rs2),
           .inm(inm),
           .SALIDA_Alu(SALIDA_Alu),
           .SALIDA_comparativa(SALIDA_comparativa),
           .carry(carry),
           .sl_ok(sl_ok)
       
       );
       
initial begin
               
       clk=0;
       en=0;
             
      //iniciar
       operando1 = 32'hc0404040;
       rs2 = 32'h00000fff;
       inm = 32'h00000fff;
       decinst = 12'b000000110011;
       reset=1; 
       en=0;                                                                                        
       #20;
              
       //para que reste
       
       decinst = 12'b100000110011;
       reset=0;
       en=0;                                                                                        
        #20;
      
       //para que reste
              
          decinst = 12'b100000110011;
          reset=0; 
          en=1;                                                                                        
          #20;
       //para que sume
            //operando1 = 32'h0000000f;
            //rs2 = 32'h00000fff;            
            decinst = 12'b000000110011;
            reset=0; 
            #20;
         //para que compare SLT
                                   
           decinst = 12'b000100010011;
           reset=0; 
        #20;
          //para que desplaze  SRA
                                         
         decinst = 12'b011010010011;
         reset=0; 
         en=1;
          #20;
end
always #5 clk=~clk;          
         
endmodule
