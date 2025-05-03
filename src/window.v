/**************************************
Author: J.W Tang
Email: jaytang1987@hotmail.com
Module: window
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

module window(clk,datavalid,pix_in_current,pix_in_previous,A,B,C,D);

input clk,datavalid,pix_in_current,pix_in_previous;
output reg A,B,C,D;

always@(posedge clk)
	if(datavalid)begin
		A<=B;B<=pix_in_previous;
		C<=D;D<=pix_in_current;
	end
	
endmodule
