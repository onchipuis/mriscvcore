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

//-- Contador módulo M

///-------
always @(posedge clk_in)
		
		if (!RESET || !enable)
			begin
				divcounter = 32'b0;
				clk_out   = 1'b0;
			end
		else if (divcounter == freq - 1) 
			begin
				divcounter =  32'b0;
				clk_out    =   1'b1;
		   end

		else 
			begin
				divcounter = divcounter + 1;
				clk_out   = 0; 
		end

//-- Sacar el bit mas significativo por clk_out
//assign clk_out = divcounter[N-1];

endmodule