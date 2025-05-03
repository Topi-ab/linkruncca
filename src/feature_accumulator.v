/**************************************
Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: feature_accumulator
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

By using LinkRunCCA in any or associated publication,
you agree to cite it as: 
Tang, J. W., et al. "A linked list run-length-based single-pass
connected component analysis for real-time embedded hardware."
Journal of Real-Time Image Processing: 1-19. 2016.
doi:10.1007/s11554-016-0590-2. 

***************************************/

module feature_accumulator(
	clk,rst,datavalid,DAC,DMG,CLR,dp,d
);

parameter imwidth=512;
parameter imheight=512;
parameter x_bit=9;
parameter y_bit=9;
parameter address_bit=8;
parameter data_bit=38;
parameter latency=3; //latency to offset counter x, 3 if holes filling, else 1
parameter rstx=imwidth-latency;
parameter rsty=imheight-1;
parameter compx=imwidth-1;
input clk,rst,datavalid,DAC,DMG,CLR;
input [data_bit-1:0]dp;
output reg[data_bit-1:0]d;

////coordinate counter
reg [x_bit-1:0]x;
reg [y_bit-1:0]y;
always@(posedge clk or posedge rst)
	if(rst)begin 
		x<=rstx[x_bit-1:0];y<=rsty[y_bit-1:0];
	end
	else if(datavalid)begin
		if(x==compx[x_bit-1:0])begin
			x<=0;
			if(y==rsty[y_bit-1:0])
				y<=0;
			else y<=y+1;
		end
		else x<=x+1;
	end

/////register d
wire [x_bit-1:0]minx,maxx,minx1,maxx1;
wire [y_bit-1:0]miny,maxy,miny1,maxy1;
//data accumulate
assign minx1=(DAC&(x<d[data_bit-1:data_bit-x_bit]))?x:d[data_bit-1:data_bit-x_bit];
assign maxx1=(DAC&(x>d[data_bit-x_bit-1:2*y_bit]))?x:d[data_bit-x_bit-1:2*y_bit];
assign miny1=(DAC&(y<d[2*y_bit-1:y_bit]))?y:d[2*y_bit-1:y_bit];
assign maxy1=(DAC&(y>d[y_bit-1:0]))?y:d[y_bit-1:0];
//data merge
assign minx=(DMG&(dp[data_bit-1:data_bit-x_bit]<minx1))?dp[data_bit-1:data_bit-x_bit]:minx1;
assign maxx=(DMG&(dp[data_bit-x_bit-1:2*y_bit]>maxx1))?dp[data_bit-x_bit-1:2*y_bit]:maxx1;
assign miny=(DMG&(dp[2*y_bit-1:y_bit]<miny1))?dp[2*y_bit-1:y_bit]:miny1;
assign maxy=(DMG&(dp[y_bit-1:0]>maxy1))?dp[y_bit-1:0]:maxy1;

always@(posedge clk or posedge rst)
	if(rst)
		d<={{x_bit{1'b1}},{x_bit{1'b0}},{y_bit{1'b1}},{y_bit{1'b0}}};
	else if(datavalid)
		if(CLR)
			d<={{x_bit{1'b1}},{x_bit{1'b0}},{y_bit{1'b1}},{y_bit{1'b0}}}; //CLR
		else d<={minx,maxx,miny,maxy};

endmodule
