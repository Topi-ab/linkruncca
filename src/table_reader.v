/**************************************
Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: table_reader
Date: 2016-04-24

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

By using this component in any associated publication,
you agree to cite it as: 
Tang, J. W., et al. "A linked list run-length-based single-pass
connected component analysis for real-time embedded hardware."
Journal of Real-Time Image Processing: 1-19. 2016.
doi:10.1007/s11554-016-0590-2. 

***************************************/

module table_reader(
	clk,rst,datavalid, //global input
	A,B,r1,r2,d,O,HCN, //input from other modules
	d_we,d_waddr,h_rdata,t_rdata,n_rdata,d_rdata,h_wdata,t_wdata, //input from table
	h_raddr,t_raddr,n_raddr,d_raddr, //output to table
	p,hp,np,tp,dp,fp,fn //output to others module
);

parameter address_bit=9;
parameter data_bit=38;

input clk,rst,datavalid,A,B,r1,r2,O,HCN,d_we;
input [address_bit-1:0]d_waddr,h_rdata,t_rdata,n_rdata,h_wdata,t_wdata;
input [data_bit-1:0]d,d_rdata;
output [address_bit-1:0]n_raddr,h_raddr,t_raddr,d_raddr;
output reg [address_bit-1:0]p,hp,np;
output [address_bit-1:0]tp;
output [data_bit-1:0]dp;
output reg fp,fn;

reg [address_bit-1:0]Rtp;
reg [data_bit-1:0]Rdp;

////label counter p
reg [address_bit-1:0]pc;
always@(posedge clk or posedge rst)
	if(rst)begin
		pc<=0;p<=0;
	end
	else if(datavalid)begin
		p<=pc;
		if(r1&~r2)begin
			pc<=pc+1;
		end	
	end

//////primary tables
assign n_raddr=pc;
assign h_raddr=pc;

//////secondary tables
assign t_raddr=(HCN)?h_wdata:h_rdata; 
assign d_raddr=(HCN)?h_wdata:h_rdata;

//////previous row run cache
wire DCN;
assign DCN=(d_we)&(d_waddr==hp);

assign tp=(~A&B)?t_rdata:Rtp;
assign dp=(~A&B)?d_rdata:Rdp;
always@(posedge clk or posedge rst)
	if(rst)begin
		np<=0;hp<=0;fp<=0;fn<=0;Rtp<=0;Rdp<=0;
	end
	else if(datavalid)begin
		Rtp<=tp;Rdp<=dp;
		if(DCN)
			Rdp<=d;
		if(~B&r1)begin
			hp<=t_raddr;
			fp<=~(t_raddr==p);
			np<=n_rdata;
			fn<=(n_rdata==p);
		end
		else if(O)begin
			Rtp<=t_wdata;
			fp<=1;
			hp<=h_wdata;
		end
	end
	
endmodule
