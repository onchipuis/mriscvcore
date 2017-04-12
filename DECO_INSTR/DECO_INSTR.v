`timescale 1ns / 1ps

module DECO_INSTR(
    input clk,
    input [31:0] inst,
     //output state,
    output reg [4:0] rs1i,
    output reg [4:0] rs2i,
    output reg [4:0] rdi,
    output reg [31:0] imm,
    output reg  [11:0] code,
    output reg [11:0] codif
     );
     
    reg [31:0] immr;

    always @(posedge clk) begin
        imm <= immr;
        code <= codif;
    end

    always @* begin
        immr = {32{1'b1}};
        rdi = {5{1'b1}};
        rs1i ={5{1'b1}};
        rs2i = {5{1'b1}};
        codif = {12{1'b1}};   // ILLISN
        case (inst[6:0])
        7'b0010111,7'b0110111: begin                 // lui, auipc
            immr = {inst[31:12], {12{1'b0}}};
            rdi = inst[11:7];
            rs1i = {5{1'b0}};
            rs2i = {5{1'b0}};
            codif = {{5{1'b0}} , inst[6:0]};
        end
        7'b1101111: begin                             // jal
            immr = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            rdi = inst[11:7];
            rs1i = {5{1'b0}};
            rs2i = {5{1'b0}};
            codif = {{5{1'b0}} , inst[6:0]}; 
        end
        7'b1100111: begin                             // jalr
            if (inst[14:12] == 3'b000) begin 
                immr = {{20{inst[31]}},inst[31:20]}; 
                rs1i = inst[19:15];
                rdi = inst[11:7];
                rs2i = {5{1'b0}};
                codif = {{2{1'b0}} ,inst[14:12] , inst[6:0]};
            end
        end
        7'b1100011: begin                             // bXX
            if((inst[14] == 1'b1)||(inst[14:13] == 2'b00)) begin
                immr = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                rdi = {5{1'b0}};
                rs1i = inst[19:15];
                rs2i = inst[24:20];
                codif = {{2{1'b0}} ,inst[14:12] , inst[6:0]};
            end
        end  
        7'b0000011: begin                             // lX
            if(((inst[14] == 1'b0)&&(inst[13:12] != 2'b11))||(inst[14:13] == 2'b10)) begin // lX
                immr = {{20{inst[31]}},inst[31:20]}; 
                rs1i = inst[19:15];
                rdi = inst[11:7];
                rs2i = {5{1'b0}};
                codif = {{2{1'b0}} ,inst[14:12] , inst[6:0]};
            end
        end
        7'b0100011: begin                             // sX
            if((inst[14] == 1'b0)&&(inst[13:12] != 2'b11)) begin    // sX
                immr = {{20{inst[31]}},inst[31:25],inst[11:7]} ;
                rs1i = inst[19:15];
                rs2i = inst[24:20];
                rdi = {5{1'b0}};
                codif = {{2{1'b0}} ,inst[14:12] , inst[6:0]};
            end
        end
        7'b0010011: begin // arith & logic immr
            if (inst[13:12] != 2'b01)begin // arith immr
                rdi = inst[11:7];
                rs1i = inst[19:15];
                rs2i = {5{1'b0}};
                immr = {{20{inst[31]}},inst[31:20]}; 
                codif = {2'b00 ,inst[14:12] , inst[6:0]};
            end else /*if (inst[13:12] == 2'b01)*/ begin // sXXi
                rdi = inst[11:7];
                rs1i = inst[19:15];
                rs2i = {5{1'b0}};
                immr = {{20{inst[31]}},inst[31:20]}; 
                codif = {1'b0, inst[30] ,inst[14:12] , inst[6:0]};  // Diferentiation between SRLI and SRAI is implicit on codif
            end
        end
        7'b0110011: begin // arith and logic
            if(({inst[31], inst[29:25]} == 6'b000000) || //add,sllst,sltu,xor,srl,or,and,sub,sra (inst[30] can be 1 or 0)
               ((inst[31:25] == 7'b0000001)&&(inst[14] == 1'b0)) // mul[h[u|su]] (do not support divs)
               ) begin 
                rs2i = inst[24:20];
                rs1i = inst[19:15];
                rdi  = inst[11:7];
                immr = {32{1'b0}};
                codif = {inst[30],inst[25] ,inst[14:12] , inst[6:0]};
            end
        end
        7'b1110011: begin // ECALL, EBREAK
            if(inst[14:12] == 3'b000) begin
                // Quite the same as arith immr
                rdi = inst[11:7];
                rs1i = inst[19:15];        // WARN: This can be also zimm for CSRRX calls
                rs2i = {5{1'b0}};
                immr = {{20{1'b0}},inst[31:20]}; 
                codif = {2'b0000 ,inst[20] , inst[6:0]};
            end else if(inst[14:12] != 3'b100) begin // CSRRX
                // Quite the same as arith immr
                rdi = inst[11:7];
                rs1i = inst[19:15];        // WARN: This can be also zimm for CSRRX calls
                rs2i = {5{1'b0}};
                immr = {{20{1'b0}},inst[31:20]}; 

                codif = {2'b00 ,inst[14:12] , inst[6:0]};
            end
        end
        7'b0011000: begin // IRQ
            if (inst[14:12] != 3'b000) begin                    // IRQXX (NOT SBREAK)
                immr = {{20{inst[31]}},inst[31:20]};
                rdi = {inst[11:7]};
                rs1i = {inst[19:15]};
                rs2i = {inst[24:20]};
                codif = {{2{1'b0}} ,inst[14:12] , inst[6:0]};
            end
        end
        endcase
    end

endmodule
