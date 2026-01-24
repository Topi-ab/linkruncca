from dataclasses import dataclass


@dataclass(frozen=True)
class DutParams:
    x_size: int
    y_bits: int

    @property
    def y_size(self) -> int:
        return 1 << self.y_bits

    def wrap_y(self, y: int) -> int:
        return y % self.y_size

    @classmethod
    def from_env(cls) -> "DutParams":
        import os

        x_size = int(os.getenv("LINKRUNCCA_X_SIZE", "200"))
        y_bits = int(os.getenv("LINKRUNCCA_Y_BITS", "10"))
        return cls(x_size=x_size, y_bits=y_bits)

    @classmethod
    def from_dut(cls, dut) -> "DutParams":
        try:
            x_size = int(dut.used_x_size.value)
            y_bits = int(dut.used_y_bits.value)
        except Exception as exc:
            import cocotb

            raise cocotb.result.TestFailure(
                "DUT constants used_x_size/used_y_bits not found. "
                "Expose them on the top-level to use from_dut()."
            ) from exc
        return cls(x_size=x_size, y_bits=y_bits)
