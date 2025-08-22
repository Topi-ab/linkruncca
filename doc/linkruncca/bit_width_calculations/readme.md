# Calculating arbitrary size bith widths accurately

VHDL type `integer` is represented with finite precision signed binary representation (typically `int32_t`). This is more than enough to represent any feasible bit width in FPGA design.

But to calculate how many bits are actually needed in worst case, it is sometimes needed to calculate the maximum possible value to be held in the bit-vector, which can easily be more that `integer` data-type can represent. Working with floating-points can (if `float64_t` is used internally) extend the range a bit, but not enough.

This code base employs vhdl type `unsigned` (`ieee.numeric_std`) which allows to do calculations on any selected value range.

## Support functions

in [vhdl_linkruncca_util_pkg.vhdl](../../../src/vhdl/vhdl_linkruncca_util_pkg.vhdl) several helper functions are declared:

- `fit(a: unsigned; extra_bits: natural := 0) return unsigned`
- `fit(a: integer; extra_bits: natural := 0) return unsigned`

These two `fit()` functions return MSB-trimmed version of `a`, with `extra_bits` number of trailing '0' bits. I.e. it automatically keeps only meaningful bits and the return value is the same as `a` parameter, in `unsigned` type.

- `sum_x(x1, x2: integer) return integer`
- `sum_x(x1, x2: integer) return unsigned`

These two `sum_x()` functions return the arithmetic sum from x1 to x2 (both inclusive).
<br>The `unsigned` return type can handle any input range.

$$ret = \sum_{x=X_1}^{X_2} x$$

- `sum_x2(x1, x2: integer) return integer`
- `sum_x2(x1, x2: integer) return unsigned`

$$ret = \sum_{x=X_1}^{X_2} x^2$$

These two `sum_x2()` functions return the arthmetic sum of $X^2$ for from x1 to x2 (both inclusive).
<br>The `unsigned` return type can handle any input range.

- `sum_xy(x1, x2, y1, y2: integer) return integer`
- `sum_xy(x1, x2, y1, y2: integer) return unsigned`

These two `sum_xy()` functions return the sum of $X \cdot Y$ for every combination of (x,y) in the range x1 to x2 and y1 to y2.
<br>The `unsigned` return type can handle any input range.

$$ret = \sum_{x=X_1}^{X_2} ( \sum_{y=Y_1}^{Y_2} (x \cdot y))$$

- `max2bits(a: integer) return integer`
- `max2bits(a: unsigned) return integer`

These two `max2bits()` functions (max value to required number of bits) return the exact number of bits required to represent `a` as unsigned integer.

- `min(a, b: unsigned) return unsigned`
- `max(a, b: unsigned) return unsigned`

These two functions return min/max value of the arguments `a` and `b`.

## Usage

`constant x2_sum_bits: integer := max2bits(unsigned'(sum_x2(0, X2))*fit(Y_size));`

This example calculates number of bits required to store
$$Y_{size} \cdot \sum_{x=0}^{X2} x^2$$

Which in linkruncca's case is the maximum value of x squared within image (all pixels active).

`fit(Y_size)` converts Y_size to unsigned (required number of bits)
<br> `unsigned'sum_x2(0, X2)` calculates the sum of 0..X2, and returns unsigned. Note that the `unsigned'` prefix calls for function with `unsigned` return type.

`*` calculates multiplication of two unsigned, and extends the size to left_bits + right_bits.

If addition is used in formula, `extra_bits` needs to be set as unsigned addition (in numeric_std) does not increase bit width automatically. Select suitable number of extra MSB (0) bits which guarantees that there is no overflow.

## Restrictions

This should work fine in all simulation code, and elaboration phase of synthesizable code.
