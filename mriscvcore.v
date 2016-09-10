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

wire [31:0] rd, rs1, rs2, imm, pc;

// DATAPATH PHASE	*************************************************************
memory_interface memory_interface_int(
    .clock(clk),
    .resetn(rstn),
    .rs1(rs1),
    .rs2(rs2),
	.Rdata_mem(Rdata),
    .ARready(ARready),
	.Rvalid(Rvalid),
	.AWready(AWready),
	.Wready(Wready),
	.Bvalid(Bvalid),
	.imm(imm), 
    .W_R(W_R),
    .wordsize(wordsize),
    .enable(enable),
	.pc(pc),
	.signo(signo),
	.busy(busy), 
	.done(done),
	.alineado(alineado), 
	.AWdata(AWdata),
	.ARdata(ARdata),
	.Wdata(Wdata),
	.rd(rd),
	.inst(inst),
	.ARvalid(ARvalid),
	.RReady(RReady),
	.AWvalid(AWvalid),
	.Wvalid(Wvalid),
	.arprot(ARprot),
	.awprot(AWprot),
	.Bready(Bready),
	.Wstrb(Wstrb)
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
	
ALU_PROJECT ALU_PROJECT_inst(
    .clk(clk),
	.reset(rstn),
	.en(en),
	.decinst(decinst),
	.rs2(rs2),
	.inm(inm),
	.operando1(operando1),
	.SALIDA_Alu(SALIDA_Alu),
	.SALIDA_comparativa(SALIDA_comparativa),
	.carry(carry),
	.sl_ok(sl_ok)
	);
	
DecInstr1 DecInstr1_inst(
	.inst(inst),
	.clock(clk),
	.resetDec(resetDec),
	.enableDec(enableDec),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.imm_out(imm_out),
	.codif(flag)
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

MulU MulU_inst(
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
