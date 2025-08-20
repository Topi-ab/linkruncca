# Linescan mode of linkruncca module

## Problem statement

Linescan sensors do not have native Y-coordinate. The image format is X_SIZE * 1 pixels.

They are typically used in conveyor belts, or other setup where the object is moving across the image area.

In this mode, there is no separation of picture data to frames, from where connected components are detected. Rather the connected component analysis need to be continuous process, and independent of Y-coordinates where the object is.

In area sensor mode, the object is detected only from one frame, and any overlapping between frames (of object) will result in two separate detections.

## Method used

Virtual Y-coordinate is introduced. Rolling over counter (e.g. 8 bits in this text) Y-counter is used, which starts from 0, counts upto 255, and rolls over back to zero.

In addition to Virtual Y-counter, virtual frame (based on virtual Y-coordinate) is divided to two segments. Segment 0 for Y-coordinates 0-127, and segment 1 for Y-coordinates 128-255. The segment is equal to MSB of Y-counter.

For selected statistical variables, the data collection structure (linkruncca_feature_t) has separate field for segment 0 (seg0) and for segment 1 (seg1).

The variables are

- x_left (the smallest X-coordinate of the object, shared for both segments)
- x_right (the greatest X-coordinate of the object, shared for both segments)
- y_top_seg0 (the smallest y-coordinate of the object within segment 0)
- y_top_seg1 (the smallest y-coordinate of the object within segment 1)
- y_bottom_seg0 (the greatest y-coordinate of the object within segment 0)
- y_bottom_seg1 (the greatest y-coordinate of the object within segment 1)
- x2_sum (sum of squares of X-coordinates of the object, shared for both segments)
- ylow2_sum (sum of squares of Y_LOW-coordinates of the object, shared for both segments)
- xylow_sum (sum of X-coordinate*Y_LOW-coordinate of the object, shared for both segments)
- x_seg0_sum (sum of X-coordinates of the object within segment 0)
- x_seg1_sum (sum of X-coordinates of the object within segment 1)
- ylow_seg0_sum (sum of Y_LOW-coordinates of the object within segment )
- ylow_seg1_sum (sum of Y_LOW-coordinates of the object within segment )
- n_seg0_sum (number of pixels of the object within segment 0)
- n_seg1_sum (number of pixels of the object within segment 1)

The Y_LOW coordinate above is the Y-coordinate without MSB bit (Y mod 128 for 8-bit Y-counter). I.e. the y-coordinate within the segment where the pixel resides.

If single object has both n_seg0_sum and n_seg1_sum as non-zero, then the object has present in both segments.

y_top_seg0/1 and y_bottom_seg0/1 can be used to analyze which is the start segment and which is the end segment. See `vhdl_linkruncca_pkg_ellipses_linescan.vhdl` for code.

### Calculating second moments from accumulators

There are 4 distinct cases for objects:
1. The object is entirely within segment 0
2. The object is entirely within segment 1
3. The object starts in segment 0, and extends to segment 1
4. The object starts in segment 1, and extends to segment 0

For calculation of ellipse parameters we need second order moment data, which can be calculated from the acuumulators above.

For cases 1,2 and 3:

The coordinates are transposed to segment 0 coordinates (i.e. Y-coordinate 10 on segment 1 is transposed to 10 + 128 = 138).

- n_sum = n_seg0_sum + n_seg1_sum
- x_sum = x_seg0_sum + x_seg1_sum
- y_sum = (ylow_seg0_sum + ylow_seg1_sum) + 128\*n_seg1_sum
- y2_sum = ylow2_sum + 2\*128\*ylow_seg1_sum + 128\*128\*n_seg1_sum
- x2_sum = x2_sum
- xy_sum = xylow_sum + 128\*x_set1_sum

For the case 4:

The coordinates are transposed to segment 0 coordinates. The segment 1 was preceding segment 0 so segment 1 coordinates are negative (i.e. Y-coordinate 10 on segment 1 is transposed to 10 - 128 = -118).

- n_sum = n_seg0_sum + n_seg1_sum
- x_sum = x_seg0_sum + x_seg1_sum
- y_sum = ylow_seg0_sum + ylow_seg1_sum - 128\*n_seg1_sum
- y2_sum = ylow2_sum - 2\*128\*ylow_seg1_sum + 128\*128\*n_seg1_sum
- x2_sum = x2_sum
- xy_sum = xylow_sum - 128\*x_seg1_sum

## Derivation of formulas

$Y_{low0}$ is $Y_{low}$ coordinate when the pixel is in segment 0.
$\\ Y_{low1}$ is $Y_{low}$ coordinate when the pixel is in segment 1.

### For cases 1,2 and 3:

The Y-coordinate in full scale (0-255 in 8-bit example) can be reconstructed from y_low (7 LSB bits) and MSB bit by:

$Y = Y_{low} + heigth_{segment} \cdot MSB$

Note that MSB is either 0, or 1, so 
$\\ MSB^2 = MSB$

and $height_{segment}$ is half the full Y-scale (128 in 8-bit example).

Derivation process:

$$
\begin{aligned}
& sum_y = \sum_{} Y \\
& = \sum_{} (Y_{low} + height_{segment} \cdot MSB) \\ 
& = \sum_{} Y_{low0} + \sum_{} Y_{low1} + height_{segment} \cdot \sum_{} MSB \\
\\ \\
& sum_{y2} = \sum Y^2 \\
& = \sum (Y_{low} + height_{segment} \cdot MSB )^2 \\
& = \sum (Y_{low}^2 + 2 \cdot Y_{low} \cdot height_{segment} \cdot MSB + height_{segment}^2 \cdot MSB^2) \\
& =  \sum Y_{low0}^2 + \sum Y_{low1}^2 + 2 \cdot height_{segment} \cdot \sum Y_{low1} + height_{segment}^2 \cdot \sum MSB\\
\\ \\
& sum_{xy} = \sum (X \cdot Y) \\
& = \sum (X \cdot (Y_{low} + height_{segment} \cdot MSB)) \\
& = \sum (X \cdot Y_{low}) + \sum (X \cdot height_{segment} \cdot MSB) \\
& =  \sum (X \cdot Y_{low}) + height_{segment} \cdot \sum (X \cdot MSB) \\
\end{aligned}
$$

### For case 4:

The Y-coordinate in full scale (0-255 in 8-bit example) can be reconstructed from y_low (7 LSB bits) and MSB bit by (the data on segment 1 precedes in Y-coordinates the data on segment 0):

$Y = Y_{low} - heigth_{segment} \cdot MSB$

Note that MSB is either 0, or 1, so 
$\\ MSB^2 = MSB$

where $height_{segment}$ is half the full Y-scale (128 in 8-bit example).

Derivation process:

$$
\begin{aligned}
& sum_y = \sum Y \\
& = \sum (Y_{low} - height_{segment} \cdot MSB) \\ 
& = \sum Y_{low0} + \sum Y_{low1} - height_{segment} \cdot \sum MSB \\
\\ \\
& sum_{y2} = \sum Y^2 \\
& = \sum (Y_{low} - height_{segment} \cdot MSB )^2 \\
& = \sum (Y_{low}^2 - 2 \cdot Y_{low} \cdot height_{segment} \cdot MSB + height_{segment}^2 \cdot MSB^2) \\
& =  \sum Y_{low0}^2 + \sum Y_{low1}^2 - 2 \cdot height_{segment} \cdot \sum Y_{low1} + height_{segment}^2 \cdot \sum MSB\\
\\ \\
& sum_{xy} = \sum (X \cdot Y) \\
& = \sum (X \cdot (Y_{low} - height_{segment} \cdot MSB)) \\
& = \sum (X \cdot Y_{low}) - \sum (X \cdot height_{segment} \cdot MSB) \\
& =  \sum (X \cdot Y_{low}) - height_{segment} \cdot \sum (X \cdot MSB) \\
\end{aligned}
$$
