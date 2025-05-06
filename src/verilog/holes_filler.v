/**************************************
Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: holes_filler
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

module holes_filler(clk,datavalid,pix_in_current,pix_in_previous,left,pix_out);

input clk,datavalid,pix_in_current,pix_in_previous;
output reg left;
output pix_out;

reg top,x,right;


//window
always@(posedge clk)
	if(datavalid)begin
		top<=pix_in_previous;
		left<=x;x<=right;right<=pix_in_current;
	end

assign pix_out=(top&(left|right))?1'd1:x;


endmodule
