/**************************************
Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: LinkRunCCA
Date: 2016-04-24
Description: Top level of LinkRunCCA Hardware Module.

Copyright (C) 2016 J.W. Tang
----------------------------
This file is part of LinkRunCCA.

LinkRunCCA is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

LinkRunCCA is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with LinkRunCCA. If not, see <http://www.gnu.org/licenses/>.

By using LinkRunCCA in any or associated publication,
you agree to cite it as: 
Tang, J. W., et al. "A linked list run-length-based single-pass
connected component analysis for real-time embedded hardware."
Journal of Real-Time Image Processing: 1-19. 2016.
doi:10.1007/s11554-016-0590-2.  

***************************************/

module LinkRunCCA(clk,rst,datavalid,pix_in,datavalid_out,box_out);

`include "cca.vh" //parameters file

parameter x_bit=$clog2(imwidth); 
parameter y_bit=$clog2(imheight);
parameter address_bit=x_bit-1;
parameter data_bit=2*(x_bit+y_bit);
parameter latency=3; //latency is 3 with holes_filler

input clk,rst,datavalid,pix_in;
output reg datavalid_out;
output reg [data_bit-1:0]box_out;

//rams' wires
wire [address_bit-1:0]n_waddr,n_wdata,n_raddr,n_rdata;
wire [address_bit-1:0]h_waddr,h_wdata,h_raddr,h_rdata;
wire [address_bit-1:0]t_waddr,t_wdata,t_raddr,t_rdata;
wire [address_bit-1:0]d_raddr,d_waddr;
wire [data_bit-1:0] d_rdata,d_wdata;
wire n_we,h_we,t_we,d_we;

//connection wires
wire A,B,C,D,r1,r2,fp,fn,O,HCN,DAC,DMG,CLR,EOC;
wire [address_bit-1:0]p,hp,tp,np;
wire [data_bit-1:0]d,dp;
wire left,hr1,hf_out;


//tables
table_ram#(address_bit,address_bit)
	Next_Table(clk,n_we&datavalid,n_waddr,n_wdata,n_raddr,n_rdata);
table_ram#(address_bit,address_bit)
	Head_Table(clk,h_we&datavalid,h_waddr,h_wdata,h_raddr,h_rdata);
table_ram#(address_bit,address_bit)
	Tail_Table(clk,t_we&datavalid,t_waddr,t_wdata,t_raddr,t_rdata);
table_ram#(data_bit,address_bit)
	Data_Table(clk,d_we&datavalid,d_waddr,d_wdata,d_raddr,d_rdata);

//holes filler
holes_filler HF(clk,datavalid,pix_in,hr1,left,hf_out);
row_buf#(imwidth-2) RBHF(clk,datavalid,left,hr1);



//window & row buffer
window WIN(clk,datavalid,hf_out,r1,A,B,C,D);
row_buf#(imwidth-2) RB(clk,datavalid,C,r1,r2);

//table reader
table_reader#(address_bit,data_bit) TR(
	clk,rst,datavalid, //global input
	A,B,r1,r2,d,O,HCN, //input from other modules
	d_we,d_waddr,h_rdata,t_rdata,n_rdata,d_rdata,h_wdata,t_wdata, //input from table
	h_raddr,t_raddr,n_raddr,d_raddr, //output to table
	p,hp,np,tp,dp,fp,fn //output to others module
);

//equivalence resolver
equivalence_resolver#(address_bit,data_bit) ES(
	clk,rst,datavalid, //global input
	A,B,C,D,p,hp,np,tp,dp,fp,fn,d, //input from other modules
	h_we,t_we,n_we,d_we, //output to table (write enable)
	h_waddr,t_waddr,n_waddr,d_waddr, //output to table (write address)
	h_wdata,t_wdata,n_wdata,d_wdata, //output to table (write data)
	HCN,DAC,DMG,CLR,EOC,O //output to other modules
);


//feature accumulator
feature_accumulator#(
	.imwidth(imwidth),
	.imheight(imheight),
	.x_bit(x_bit),
	.y_bit(y_bit),
	.address_bit(address_bit),
	.data_bit(data_bit),
	.latency(latency)
	)
	FA(
	clk,rst,datavalid,DAC,DMG,CLR,dp,d
);


//registered data output
always@(posedge clk or posedge rst)
	if(rst)begin
		datavalid_out<=0;
	end
	else if(datavalid)begin
		datavalid_out<=0;
		box_out<=dp;
		if(EOC)
			datavalid_out<=1;
	end

endmodule
