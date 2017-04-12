`timescale 1ns / 1ps

module divM(
    input wire clk_in, enable,
    input wire RESET,
    input wire [31:0] freq,
    output reg clk_out);

    //-- Valor por defecto del divisor
    //-- Como en la iCEstick el reloj es de 12MHz, ponermos un valor de 12M
    //-- para obtener una frecuencia de salida de 1Hz

    //assign M = freq;
    // M = 12_000_000;

    //-- Numero de bits para almacenar el divisor
    //-- Se calculan con la funcion de verilog $clog2, que nos devuelve el 
    //-- numero de bits necesarios para representar el numero M
    //-- Es un parametro local, que no se puede modificar al instanciar
    localparam N = 32;

    //-- Registro para implementar el contador modulo M
    reg [N-1:0] divcounter = 0;

    //-- M module counter
    always @(posedge clk_in)
        if (!RESET || !enable)
        begin
            divcounter = 32'b0;
            clk_out    =  1'b0;
        end else if (divcounter == freq - 1) begin
            divcounter = 32'b0;
            clk_out    =  1'b1;
        end else begin
            divcounter = divcounter + 1;
            clk_out    = 0; 
        end

endmodule

module Count(
    input clk_in, enable,
    input wire [31:0]freq,
    input wire [31:0] Max_count,
    input RESET,
    output reg Ready_count,
    output wire [31:0] Count_out
    );

    wire clk;
    reg [31:0] Max_count_int, freq_int;
    reg enable_int,Ready_count_int    ;
    
    divM instance_name (
    .clk_in(clk_in),
     .enable(enable_int),
     .freq(freq_int),
     .RESET(RESET),
     .clk_out(clk)
    );
    
    localparam N = 32;
    reg b;wire c;    
    always @(posedge clk_in)
        if (!RESET)    begin
            enable_int   = 0;
            Ready_count  = 1'b0;
        end else if (enable) begin
            enable_int   = 1;
            Ready_count  = 1'b0;
            b            = 1'b1;
        end    else if (Ready_count_int) begin
            enable_int   = 0; 
            b  =  1'b0;
            Ready_count = c;
        end    else begin
            Ready_count = c;
        end
            
    assign c = b? Ready_count_int:1'b0;
      always @(posedge clk_in)
      if (!RESET)
        begin
            Max_count_int = 32'b0;
            freq_int      = 32'b0;
        end    else if (enable_int) begin
            Max_count_int = Max_count;
            freq_int      = freq;
        end    else begin
            Max_count_int = 32'b0;
            freq_int      = 32'b0;
        end

  
    reg [N-1:0] divcounter = 0;

    //-- M module counter
    always @(posedge clk_in)
        if (!RESET ) begin
            divcounter = 32'b0;
            Ready_count_int   = 1'b0;
        end else if (clk && enable_int) begin
            if (divcounter == Max_count_int ) begin
                divcounter =32'b0;
                Ready_count_int   = 1'b1;
            end else begin
                divcounter = divcounter + 1;
                Ready_count_int   = 1'b0; 
            end
        end
      assign Count_out = divcounter;
endmodule

module IRQ(
    input rst,clk,savepc,en,
    input [11:0] instr,
    input [31:0] rs1, rs2, inirr, pc, imm,
    output [31:0] rd, addrm, outirr, pc_irq, pc_c, // pc_c es el pc en dónde se estaba antes de la irr, a donde hay q volver una vez finalice la(s) irr
    output flag
    );

    reg flag_q,irr_tisirr,enable,irr_ebreak;
    wire any_inirr,any_regirr,rs1_chg,act_irr,flag_ind,imm_chg,R_C;
    wire [31:0] ss2,erased_irrstate,irrstate,C_O,irr_toerase;
    reg [31:0] regirr,pc_c_q,addrm_q,true_irrstate,m6,rs1t,immt,timer_count,timer_max_count,div_freq,q,irrstate_rd,pc_irq_reg,rd1;
    reg [8:0] instr_sel;
    
    wire is_ebreak;
    wire is_addrms;
    wire is_addrme;
    wire is_tisirr;
    wire is_irrstate;
    wire is_clraddrm;
    wire is_clrirq;
    wire is_retirq;
    wire is_addpcirq;
    
    ////////////////////////////////////////////////////////////.
    // ** Interruption generation
    assign any_inirr = inirr ? 1:0;
    
    always@(posedge clk) // ebreak interrupt
        if (!rst) irr_ebreak=0;
        else if (is_ebreak) irr_ebreak=1;
        else irr_ebreak=0;
    
    always@(posedge clk) // timer interrupt
        if(!rst) begin 
            enable=0; 
            irr_tisirr=0; 
            timer_count=0; 
            div_freq=0; 
            timer_max_count=0; 
        end else if (is_tisirr) begin 
            enable=1; 
            irr_tisirr=0; 
            timer_count=0; 
            div_freq=rs1; 
            timer_max_count=rs2; 
        end    else begin
            enable=0; 
            irr_tisirr=R_C; 
            timer_count=C_O;     // Basically is not used
            div_freq=0; 
            timer_max_count=0; 
        end
    Count timer_counter (
        .clk_in(clk), 
        .enable(enable), 
        .freq(div_freq), 
        .Max_count(timer_max_count), 
        .RESET(rst), 
        .Ready_count(R_C), 
        .Count_out(C_O)
        );

    always@(posedge clk)
        if(!rst) regirr=0;
        else regirr={inirr[31:2],irr_tisirr,irr_ebreak};
        
    assign any_regirr = regirr ? 1:0;
    
    ////////////////////////////////////////////////////////////
    // ** Interrupt erasing and flagging
        
    // irr_toerase assign, this is the interrupt indicated to be erased via 'is_clrirq'
    assign irr_toerase=rs1|imm;
    assign erased_irrstate = (~irr_toerase)&true_irrstate;
    
    // Update new irrstate
    always@(posedge clk)
        if(!rst) true_irrstate<=0;
        else if(is_clrirq) true_irrstate <= erased_irrstate;
        else true_irrstate <= regirr | true_irrstate;
        
    assign irrstate = true_irrstate;
    
    // Acknoledge generation
    always@(posedge clk)
        if (!rst) q<=0;
        else if (is_clrirq) q<=irr_toerase&true_irrstate;
        else q<=0;
    assign outirr=q;
        
    // Flag generation
    assign act_irr = irrstate? 0:1;         // Active irr indicator
    assign flag_ind= act_irr & is_retirq;     // Flag indicator    
    always@(posedge clk)                     // Flag
        if(!rst) flag_q=0;
        else if(any_inirr) flag_q=1;
        else if (flag_ind) flag_q=0;
        else flag_q=flag_q; 
    assign flag=flag_q;
    
    ////////////////////////////////////////////////////////////
    // ** Instruction Selector
    always @* 
        case({instr,en})
            13'b0000001110011: begin instr_sel = 9'b000000001;     rd1=0;          end     //EBREAK 0 
            13'b0000100110001: begin instr_sel = 9'b000000010;     rd1=0;          end     //ADDRMS 1 
             13'b0001000110001: begin instr_sel = 9'b000000100;     rd1=addrm_q;     end      //ADDRME 2
            13'b0001100110001: begin instr_sel = 9'b000001000;     rd1=0;          end      //TISIRR 3 
            13'b0010000110001: begin instr_sel = 9'b000010000;     rd1=irrstate_rd;end      //IRRSTATE 4
            13'b0010100110001: begin instr_sel = 9'b000100000;     rd1=0;          end      //CLRADDRM 5
            13'b0011000110001: begin instr_sel = 9'b001000000;     rd1=0;          end      //CLRIRQ 6
            13'b0011100110001: begin instr_sel = 9'b010000000;     rd1=0;          end      //RETIRQ 7
            13'b0000000110001: begin instr_sel = 9'b100000000;     rd1=0;          end      //ADDPCIRQ 8
            default          : begin instr_sel = 9'b000000000;     rd1={32{1'bz}};    end
        endcase
    assign is_ebreak   = instr_sel[0];
    assign is_addrms   = instr_sel[1];
    assign is_addrme   = instr_sel[2];
    assign is_tisirr   = instr_sel[3];
    assign is_irrstate = instr_sel[4];
    assign is_clraddrm = instr_sel[5];
    assign is_clrirq   = instr_sel[6];
    assign is_retirq   = instr_sel[7];
    assign is_addpcirq = instr_sel[8];
    
    assign rd=rd1;
        
    /////////////////////////////////////////////////////////////
    // ** Instruction - dedicated registers
    always@(posedge clk) // pc_irq with addpcirq
        if(!rst) pc_irq_reg=0;
        else if (is_addpcirq) pc_irq_reg=rs1+imm;
        else pc_irq_reg=pc_irq_reg; 
    assign pc_irq=pc_irq_reg;
    
    always@(posedge clk) // irrstate out (rd)
        if (!rst) irrstate_rd=0;
        else if (is_irrstate) irrstate_rd=irrstate;
        else irrstate_rd=irrstate_rd;    
    
    always@(posedge clk) // Stores accord to instruction in 'addrm' and erases it
        if(!rst) addrm_q=0;
        else if (is_addrms)addrm_q=rs1;    // for addrms
        else if (is_clraddrm)addrm_q=0;    // for clraddrm
        else addrm_q=addrm_q;
    assign addrm=addrm_q;
    
    always@(posedge clk)    // Not an instruction, this is backup pc when there is an interrupt
        if(!rst) pc_c_q=0;
        else if(savepc) pc_c_q=pc;
        else pc_c_q=pc_c_q;
    assign pc_c=pc_c_q;
    
endmodule
