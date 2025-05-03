======================================================================================================
LINKRUNCCA: A Linked List Run-Length-Based Single-Pass Connected Component Analysis
======================================================================================================

Description
-----------
LinkRunCCA is a real-time single-pass connected component analysis/labelling (CCA/CCL) hardware implementation in verilog HDL. It can operate in maximum streaming throughput (one pixel per cycle) and has very low memory requirement. The implementation is based on the state-of-the-art algorithm from publication in http://dx.doi.org/10.1007/s11554-016-0590-2.

LinkRunCCA uses combination of linked list and run-length-based techniques to label and extract components' feature (bounding box in this case) in one scan. Algorithm detail is described in the publication. 


Overview of LinkRunCCA
-----------------------
                 ______________
                |              |
      pixel---->|              |---->bounding box (min X, max X, min Y and max Y coordinates)
                |  LinkRunCCA  |
      valid---->|              |---->valid_out
                |______________|

Input Ports:
clk - clock sink
rst - reset sink
pix_in - input binary image/video stream (1 bit)
datavalid - valid bit for input stream

Output Ports:
box_out - bounding box of each component (concatenated min X, max X, min Y and max Y coordinates)
datavalid_out - valid bit for each bounding box

Parameters:
imwidth - image width
imheight - image height


Using LinkRunCCA
----------------
LinkRunCCA accepts binary image/video stream as input and produces bounding boxes of each connected component in the image/video. It can be connected directly to any streaming interfaces up to one pixel per cycle throughput, consisting of a data bit (binary pixel) and a valid bit. Bounding box of each connected component is produced immediately as soon as the component is completed, accompanied with a valid_out bit.

The size of image/video is parametrizable, hence the memory requirement is varied based on image/video size. The parameters (imwidth and imheight) must be set correctly according to the image size for implementation.


Authors and Contact Details 
---------------------------
Author: J.W. Tang		
Email: jaytang1987@hotmail.com


Citation
--------
By using LinkRunCCA in any or associated publication, you agree to cite it as: 
Tang, J. W., et al. "A linked list run-length-based single-pass connected component analysis for real-time embedded hardware." Journal of Real-Time Image Processing: 1-19. 2016. doi:10.1007/s11554-016-0590-2. 


Copyright (C) 2016 J.W. Tang
----------------------------
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


