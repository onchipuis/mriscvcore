`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
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
	reg enable_int,Ready_count_int	;
//	wire freq;
	divM instance_name (
    .clk_in(clk_in),
	 .enable(enable_int),
	 .freq(freq_int),
	 .RESET(RESET),
	 .clk_out(clk)
    );
//	 assign clk=clk_out;
//	 assign M = Max_count; 
	 localparam N = 32;
	 reg b;wire c;	
	 always @(posedge clk_in  or negedge RESET  )
  if (!RESET)
			begin
			 enable_int   = 0;
			 Ready_count  = 1'b0;
			end
			else if (enable )
			begin
				 enable_int   = 1;
				 Ready_count  = 1'b0;
				 b            =1'b1;
			end
/*			else if ( Ready_count_int & (Count_out==0))
				begin
			   enable_int   = 1; 
				Ready_count  = 1'b1;
				end
		  else if (Ready_count_int & (Count_out==1))
				begin				   
				enable_int   = 0; 
				 Ready_count  = 1'b0;
				end
*/

			else if (Ready_count_int)
				begin
			   enable_int   = 0; 
				b  =  1'b0;
				Ready_count = c;
				end

				else 
				begin
				Ready_count = c;
				end
			
	assign c = b? Ready_count_int:1'b0;
  always @(posedge clk_in  or negedge RESET )
  if (!RESET)
			begin
				Max_count_int = 32'b0;
				 freq_int     = 32'b0;
//				 enable_int   = 0;
//				 Ready_count  = 32'b0;
			end
		else if (enable_int) 
			begin
				 Max_count_int = Max_count;
				 freq_int   = freq;
//				 enable_int   = 1;
			end
//   		else if (Ready_count)
//				 enable_int   = 0;
			else
			begin
			    Max_count_int = 32'b0;
				 freq_int     = 32'b0;
//				 enable_int   = 0;  
			end

  
reg [N-1:0] divcounter = 0;

//-- Contador módulo M
always @(posedge clk_in or negedge RESET)


		if (!RESET )
			begin
				divcounter = 32'b0;
				Ready_count_int   = 1'b0;
			end
		else if (clk && enable_int) 
		begin
			if (divcounter == Max_count_int )
				begin
					divcounter =32'b0;
					Ready_count_int   = 1'b1;
				 end

			else 
				begin
					divcounter = divcounter + 1;
					Ready_count_int   = 1'b0; 
				
			   end
	 	end

 // assign   	Count_out = (enable) ? divcounter: 32'b0;
  assign Count_out = divcounter;

//-- Sacar el bit mas significativo por clk_out
//assign time_out = divcounter[N-1];
endmodule

