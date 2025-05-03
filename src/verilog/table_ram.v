// Quartus II Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock
/* verilator lint_off BLKSEQ */

module table_ram
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=10)
(	clk,we,write_addr,data,read_addr,q);

	input [(DATA_WIDTH-1):0] data;
	input [(ADDR_WIDTH-1):0] read_addr, write_addr;
	input we, clk;
	output [(DATA_WIDTH-1):0] q;

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	reg [(ADDR_WIDTH-1):0] read_addr_reg;
	always @ (posedge clk)
	begin
	
		read_addr_reg=read_addr;
		// Write
		if (we)
			ram[write_addr] = data;

	end
	assign q= ram[read_addr_reg];
endmodule


