`timescale 1ns / 1ps

/*
mriscvcore
by CKDUR

This is the definitive core.
*/

module mriscvcore(
    input clk,
    input rstn,
    
    // AXI-4 LITE INTERFACE
    input [31:0] Rdata,
    input ARready,
    input Rvalid,
    input AWready,
    input Wready,
    input Bvalid, 
    output [31:0] AWdata,
    output [31:0] ARdata,
    output [31:0] Wdata,
    output ARvalid,
    output RReady,
    output AWvalid,
    output Wvalid,
    output [2:0] ARprot,AWprot,
    output Bready,
    output [3:0] Wstrb,
    
    // IRQ interface
    
    input [31:0] inirr,
    output [31:0] outirr,
    output trap
     
    );
    
// SIGNAL DECLARATION     *********************************************************

// Data Buses
wire [31:0] rd, rs1, rs2, imm, pc, inst;
wire [11:0] code;
wire [11:0] codif;

// Auxiliars
wire [4:0] rs1i, rs2i, rdi;

//IRQ SIGNALS
wire [31:0] pc_c, addrm, pc_irq;
wire flag;
//MEMORY INTERFACE SIGNALS
wire is_rd_mem;
wire [1:0] W_R_mem, wordsize_mem;
wire sign_mem, en_mem, busy_mem, done_mem, align_mem;
//SIGNALS DECO INST
wire enableDec;    
//SIGNALS MULT
wire enable_mul, done_mul, is_inst_mul;
//SIGNALS ALU
wire cmp, carry, enable_alu, is_inst_alu, is_rd_alu;
//SIGNALS UTILITY
wire is_inst_util, is_rd_util;
//SIGNALS FSM
wire is_exec;


// DATAPATH PHASE    *************************************************************

MEMORY_INTERFACE MEMORY_INTERFACE_inst(
    .clock(clk),
    .resetn(rstn),
    // Data buses
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(imm), 
    .pc(pc),
    .rd_en(is_rd_mem),
    // AXI4-Interface
    .Rdata_mem(Rdata),
    .ARready(ARready),
    .Rvalid(Rvalid),
    .AWready(AWready),
    .Wready(Wready),
    .Bvalid(Bvalid),
    .AWdata(AWdata),
    .ARdata(ARdata),
    .Wdata(Wdata),
    .ARvalid(ARvalid),
    .RReady(RReady),
    .AWvalid(AWvalid),
    .Wvalid(Wvalid),
    .arprot(ARprot),
    .awprot(AWprot),
    .Bready(Bready),
    .Wstrb(Wstrb),
    // To DECO_INSTR
    .inst(inst),
    // To FSM
    .W_R(W_R_mem),
    .wordsize(wordsize_mem),
    .signo(sign_mem),
    .enable(en_mem),
    .busy(busy_mem), 
    .done(done_mem),
    .align(align_mem)
    );


DECO_INSTR DECO_INSTR_inst(
    .clk(clk),
    // From MEMORY_INTERFACE
    .inst(inst),
    // Auxiliars to BUS
    .rs1i(rs1i),
    .rs2i(rs2i),
    .rdi(rdi),
    .imm(imm),
    .code(code),
    .codif(codif)
    );

REG_FILE REG_FILE_inst(
    .clk(clk),
    .rst(rstn),
    .rd(rd),
    .rdi(rdi),
    .rdw_rsrn(rdw_rsrn),
    .rs1(rs1),
    .rs1i(rs1i),
    .rs2(rs2),
    .rs2i(rs2i)
    );

    
ALU ALU_inst(
    .clk(clk),
    .reset(rstn),
    // Data Buses
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .decinst(code),
    .imm(imm),
    // To UTILITY
    .cmp(cmp),
    // To FSM
    .en(enable_alu),
    .carry(carry),
    .is_rd(is_rd_alu),
    .is_inst(is_inst_alu)
    );
    
     
IRQ IRQ_inst(
    .rst(rstn),
    .clk(clk),
    .savepc(1'b0),
    .en(1'b0),
    .instr(code),
    .rs1(rs1),
    .rs2(rs2),
    .inirr(inirr),
    .pc(pc),
    .imm(imm),
    .rd(rd),
    .addrm(addrm),
    .outirr(outirr),
    .pc_irq(pc_irq),
    .pc_c(pc_c),
    .flag(flag)
    );

MULT MULT_inst(
    .clk(clk),
    .reset(rstn),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .Enable(enable_mul),
    .is_oper(is_inst_mul),
    .Done(done_mul),
    .codif(code)
    );

UTILITY UTILITY_inst(
    .clk(clk),
    .rst(rstn),
    // FROM DATA BUS
    .rs1(rs1),
    .rd(rd),
    .opcode(code),
    .imm(imm),
    .pc(pc),
    // FROM IRQ
    .irr_ret(pc_c),
    .irr_dest(pc_irq),
    // FROM ALU
    .branch(cmp),
    // FSM
    .irr(1'b0),
    .enable_pc(enable_pc),
    .is_inst(is_inst_util),
    .is_rd(is_rd_util)
    );

// FINITE-STATE MACHINE PHASE    *************************************************

FSM FSM_inst
    (
    .clk(clk),
    .reset(rstn),
    
    // Auxiliars from DATAPATH
    .codif(codif),
    
    // Inputs from DATAPATH
    .busy_mem(busy_mem), 
    .done_mem(done_mem),
    .aligned_mem(align_mem),
    .done_exec(done_exec),
    .is_exec(is_exec),
    
    // Outputs to DATAPATH
    .W_R_mem(W_R_mem),
    .wordsize_mem(wordsize_mem),
    .sign_mem(sign_mem),
    .en_mem(en_mem),
    .enable_exec(enable_exec),
    .enable_exec_mem(enable_exec_mem),
    .trap(trap),
    .enable_pc(enable_pc)
    );
    
    // Enable Assign
    assign enable_mul = enable_exec; 
    assign enable_alu = enable_exec;
    
    // Done Assign
    assign done_exec = is_inst_util | is_inst_alu | (done_mul & is_inst_mul);
    
    // Is exec assign
    assign is_exec = ~(&(code));
    
    // Write to rd flag
    assign rdw_rsrn = (is_rd_util | is_rd_alu | done_mul | (is_rd_mem & done_mem)) & (enable_exec | enable_exec_mem);

endmodule
