# LinkRunCCA – Ellipse detection

`vhdl_linkruncca_pkg_ellipses.vhdl`, when included in the project (remove the original pkg file), collects information needed to estimate the **ellipticity** of each connected block of pixels.

---

## Collected information

For each block, the following information is collected:

- **Sum of X-Coordinates**: $\Sigma x$
- **Sum of Y-Coordinates**: $\Sigma y$
- **Sum of X \* Y**: $\Sigma (x y)$ of each foreground pixel
- **Sum of X \* X**: $\Sigma (x^2)$
- **Sum of Y \* Y**: $\Sigma (y^2)$
- **Number of foreground pixels**: $N$

These sums are computed in integer arithmetic in hardware as pixels are processed.

---

## Math needed to calculate ellipticity parameters

Given the collected sums for a block, the ellipse parameters can be computed as follows:

### 1. Center of mass (centroid)

$$
\bar{x} = \frac{\Sigma x}{N}, \qquad \bar{y} = \frac{\Sigma y}{N}
$$

### 2. Central second moments

$$
\mu_{20} = \frac{\Sigma x^2}{N} - \bar{x}^2
$$

$$
\mu_{02} = \frac{\Sigma y^2}{N} - \bar{y}^2
$$

$$
\mu_{11} = \frac{\Sigma (x y)}{N} - \bar{x}\,\bar{y}
$$

These correspond to the variances and covariance of the pixel coordinates within the block.

### 3. Covariance matrix

$$
C =
\begin{bmatrix}
\mu_{20} & \mu_{11} \\
\mu_{11} & \mu_{02}
\end{bmatrix}
$$

### 4. Eigenvalues (squared semi-axis lengths)

For a $2 \times 2$ symmetric matrix:

$$
\lambda_{1,2} =
\frac{\mu_{20} + \mu_{02}}{2}
\pm
\sqrt{
\left( \frac{\mu_{20} - \mu_{02}}{2} \right)^{2} + 
\mu_{11}^{2}
}
$$

with $\lambda_1 \ge \lambda_2$.

### 5. Axis lengths (diameters)

If the semi-axis lengths are $a = \sqrt{\lambda_1}$ and $b = \sqrt{\lambda_2}$, then:

$$
\text{Major axis length} = 2a, \qquad \text{Minor axis length} = 2b
$$

### 6. Orientation of major axis

The major axis angle $\theta$ (in radians) relative to the +X axis is:

$$
\theta = \frac{1}{2}\,\arctan2\!\left( 2\mu_{11},\, \mu_{20} - \mu_{02} \right)
$$

Note: Angles differing by ±180° represent the same axis orientation.

---

## Implementation reference

A Python demonstration implementing these exact formulas is provided in:

[py/ellipse_demonstrator.py](py/ellipse_demonstrator.py)
