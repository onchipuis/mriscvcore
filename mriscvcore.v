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
	output reg [31:0] AWdata,
	output reg [31:0] ARdata,
	output reg [31:0] Wdata,
	output reg ARvalid,
	output reg RReady,
	output reg AWvalid,
	output reg Wvalid,
	output reg [2:0] ARprot,AWprot,
	output reg Bready,
	output reg [3:0] Wstrb,
	
	// IRQ interface
	
	input [31:0] inirr,
	output [31:0] outirr
 	
	);
	
// SIGNAL DECLARATION 	*********************************************************

// Data Buses
wire [31:0] rd, rs1, rs2, imm, pc, inst;
wire [11:0] codif;

// Auxiliars
wire [4:0] rs1i, rs2i, rdi;


// DATAPATH PHASE	*************************************************************
MEMORY_INTERFACE MEMORY_INTERFACE_inst(
    .clock(clk),
    .resetn(rstn),
    
    // Data buses
    .rs1(rs1),
    .rs2(rs2),
	.rd(rd),
	.imm(imm), 
	.pc(pc),
	
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
    .W_R(W_R),
    .wordsize(wordsize),
	.signo(signo),
    .enable(enable),
	.busy(busy), 
	.done(done),
	.alineado(alineado)
	);
	
DECO_INSTR DECO_INSTR_inst(
	.clock(clk),
	
	// Auxiliars to BUS
	.rs1(rs1i),
	.rs2(rs2i),
	.inst(inst),
	.resetDec(resetDec),
	.enableDec(enableDec),
	.rd(rd),
	.imm_out(imm_out),
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
	.operando1(rs1),
	.rs2(rs2),
	.SALIDA_Alu(SALIDA_Alu),
	.decinst(codif),
	.inm(imm),
	
	// To UTILITY
	.SALIDA_comparativa(SALIDA_comparativa),
	
	// To FSM
	.en(en),
	.carry(carry),
	.sl_ok(sl_ok)
	);
	

     
IRQ IRQ_inst(
	.rst(rstn),
	.clk(clk),
	.savepc(savepc),
	.en(en),
	.instr(instr),
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
	.Enable(Enable),
	.Busy(Busy),
	.funct3(funct3)
	);

UTILITY UTILITY_inst(
	.clk(clk),
	.rst(rstn),
	.enable_int(enable_int),
	.imm(imm),
	.interrup(interrup),
	.opcode(opcode),
	.rs1(rs1),
	.branch(branch),
	.rd(rd),
	.pc(pc)
	);

// FINITE-STATE MACHINE PHASE	*************************************************

endmodule
