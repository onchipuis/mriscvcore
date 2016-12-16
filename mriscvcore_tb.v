`timescale 1 ns / 1 ps
 `define VERBOSE
 `define AXI_TEST

module mriscvcore_tb
  #(parameter memory_file = "firmware.hex");

	reg clk = 1;
	reg resetn = 0;
	reg [31:0] irq;
	wire trap;

	always @* begin
		irq = 0;
		//irq[4] = &uut.picorv32_core.count_cycle[12:0];
		//irq[5] = &uut.picorv32_core.count_cycle[15:0];
	end

	always #10 clk = ~clk;

	initial begin
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	wire        mem_axi_awvalid;
	reg         mem_axi_awready = 0;
	wire [31:0] mem_axi_awaddr;
	wire [ 2:0] mem_axi_awprot;

	wire        mem_axi_wvalid;
	reg         mem_axi_wready = 0;
	wire [31:0] mem_axi_wdata;
	wire [ 3:0] mem_axi_wstrb;

	reg  mem_axi_bvalid = 0;
	wire mem_axi_bready;

	wire        mem_axi_arvalid;
	reg         mem_axi_arready = 0;
	wire [31:0] mem_axi_araddr;
	wire [ 2:0] mem_axi_arprot;

	reg         mem_axi_rvalid = 0;
	wire        mem_axi_rready;
	reg  [31:0] mem_axi_rdata = {32{1'b0}};
	reg is_o = 0;
	reg is_ok = 0;

	mriscvcore mriscvcore_inst (
		.clk    (clk            ),
		.rstn   (resetn         ),
		.trap   (trap           ),
		.AWvalid(mem_axi_awvalid),
		.AWready(mem_axi_awready),
		.AWdata (mem_axi_awaddr ),
		.AWprot (mem_axi_awprot ),
		.Wvalid (mem_axi_wvalid ),
		.Wready (mem_axi_wready ),
		.Wdata  (mem_axi_wdata  ),
		.Wstrb  (mem_axi_wstrb  ),
		.Bvalid (mem_axi_bvalid ),
		.Bready (mem_axi_bready ),
		.ARvalid(mem_axi_arvalid),
		.ARready(mem_axi_arready),
		.ARdata (mem_axi_araddr ),
		.ARprot (mem_axi_arprot ),
		.Rvalid (mem_axi_rvalid ),
		.RReady (mem_axi_rready ),
		.Rdata  (mem_axi_rdata  ),
		//.outirr (irq            ),
		.inirr  (irq            )
	);

	reg [31:0] memory [0:64*1024/4-1];
	initial $readmemh(memory_file, memory);

	reg [63:0] xorshift64_state = 64'd88172645463325252;

	task xorshift64_next;
		begin
			// see page 4 of Marsaglia, George (July 2003). "Xorshift RNGs". Journal of Statistical Software 8 (14).
			xorshift64_state = xorshift64_state ^ (xorshift64_state << 13);
			xorshift64_state = xorshift64_state ^ (xorshift64_state >>  7);
			xorshift64_state = xorshift64_state ^ (xorshift64_state << 17);
		end
	endtask

	reg [2:0] fast_axi_transaction = ~0;
	reg [4:0] async_axi_transaction = ~0;
	reg [4:0] delay_axi_transaction = 0;

`ifdef AXI_TEST
	always @(posedge clk) begin
		xorshift64_next;
		{fast_axi_transaction, async_axi_transaction, delay_axi_transaction} <= xorshift64_state;
	end
`endif

	reg latched_raddr_en = 0;
	reg latched_waddr_en = 0;
	reg latched_wdata_en = 0;

	reg fast_raddr = 0;
	reg fast_waddr = 0;
	reg fast_wdata = 0;

	reg [31:0] latched_raddr;
	reg [31:0] latched_waddr;
	reg [31:0] latched_wdata;
	reg [ 3:0] latched_wstrb;
	reg        latched_rinsn;

	task handle_axi_arvalid; begin
		mem_axi_arready <= 1;
		latched_raddr = mem_axi_araddr;
		latched_rinsn = mem_axi_arprot[2];
		latched_raddr_en = 1;
		fast_raddr <= 1;
	end endtask

	task handle_axi_awvalid; begin
		mem_axi_awready <= 1;
		latched_waddr = mem_axi_awaddr;
		latched_waddr_en = 1;
		fast_waddr <= 1;
	end endtask

	task handle_axi_wvalid; begin
		mem_axi_wready <= 1;
		latched_wdata = mem_axi_wdata;
		latched_wstrb = mem_axi_wstrb;
		latched_wdata_en = 1;
		fast_wdata <= 1;
	end endtask

	task handle_axi_rvalid; begin
`ifdef VERBOSE
		$display("RD: ADDR=%08x DATA=%08x%s", latched_raddr, memory[latched_raddr >> 2], latched_rinsn ? " INSN" : "");
`endif
		if (latched_raddr < 64*1024) begin
			mem_axi_rdata <= memory[latched_raddr >> 2];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end else begin
			$display("OUT-OF-BOUNDS MEMORY READ FROM %08x", latched_raddr);
			$finish;
		end
	end endtask

	task handle_axi_bvalid; begin
`ifdef VERBOSE
		$display("WR: ADDR=%08x DATA=%08x STRB=%04b", latched_waddr, latched_wdata, latched_wstrb);
		if (latched_waddr == 0) $finish;
`endif
		if (latched_waddr < 64*1024) begin
			if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
			if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
			if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
			if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
		end else
		if (latched_waddr == 32'h1000_0000) begin
			if(latched_wdata == 79 || (latched_wdata == 75 && latched_wdata == 1'b1))
				is_o <= 1'b1;
			else
				is_o <= 1'b0;
			if(latched_wdata == 75 && is_o == 1'b1)
				is_ok <= 1'b1;
`ifdef VERBOSE
			if (32 <= latched_wdata && latched_wdata < 128)
				$display("OUT: '%c'", latched_wdata);
			else
				$display("OUT: %3d", latched_wdata);
`else
			$write("%c", latched_wdata);
			$fflush();
`endif
		end else begin
			$display("OUT-OF-BOUNDS MEMORY WRITE TO %08x", latched_waddr);
			$finish;
		end
		mem_axi_bvalid <= 1;
		latched_waddr_en = 0;
		latched_wdata_en = 0;
	end endtask

	always @(negedge clk) begin
		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr) && async_axi_transaction[0]) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr) && async_axi_transaction[1]) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata) && async_axi_transaction[2]) handle_axi_wvalid;
		if (!mem_axi_rvalid && latched_raddr_en && async_axi_transaction[3]) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en && async_axi_transaction[4]) handle_axi_bvalid;
	end

	always @(posedge clk) begin
		mem_axi_arready <= 0;
		mem_axi_awready <= 0;
		mem_axi_wready <= 0;

		fast_raddr <= 0;
		fast_waddr <= 0;
		fast_wdata <= 0;

		if (mem_axi_rvalid && mem_axi_rready) begin
			mem_axi_rvalid <= 0;
		end

		if (mem_axi_bvalid && mem_axi_bready) begin
			mem_axi_bvalid <= 0;
		end

		if (mem_axi_arvalid && mem_axi_arready && !fast_raddr) begin
			latched_raddr = mem_axi_araddr;
			latched_rinsn = mem_axi_arprot[2];
			latched_raddr_en = 1;
		end

		if (mem_axi_awvalid && mem_axi_awready && !fast_waddr) begin
			latched_waddr = mem_axi_awaddr;
			latched_waddr_en = 1;
		end

		if (mem_axi_wvalid && mem_axi_wready && !fast_wdata) begin
			latched_wdata = mem_axi_wdata;
			latched_wstrb = mem_axi_wstrb;
			latched_wdata_en = 1;
		end

		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr) && !delay_axi_transaction[0]) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr) && !delay_axi_transaction[1]) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata) && !delay_axi_transaction[2]) handle_axi_wvalid;

		if (!mem_axi_rvalid && latched_raddr_en && !delay_axi_transaction[3]) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en && !delay_axi_transaction[4]) handle_axi_bvalid;
	end

	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("mriscvcore_tb.vcd");
			$dumpvars(0, mriscvcore_tb);
		end
		repeat (1000000) begin
		  @(posedge clk);
		  if(is_ok) begin
		    $display("Program terminated sucesfully");
		    $finish;
		  end
		end
		$display("TIMEOUT");
		$finish;
	end

	integer cycle_counter;
	always @(posedge clk) begin
		cycle_counter <= resetn ? cycle_counter + 1 : 0;
		if (resetn && trap) begin
			repeat (10) @(posedge clk);
			$display("TRAP after %1d clock cycles", cycle_counter);
			$finish;
		end
	end
endmodule
