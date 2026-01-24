from dataclasses import dataclass
from typing import Optional, Tuple

from shapes.Shape import Pixel, Shape


@dataclass(frozen=True)
class PixelShape(Shape):
    x: int
    y: int
    kind: str = "pixel"

    def y_bounds(self) -> Tuple[int, int]:
        return (int(self.y), int(self.y))

    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        if int(y) != int(self.y):
            return None
        return (int(self.x), int(self.x))

    def GetPixel(self, x: float, y: float) -> Pixel:
        inside = int(x) == int(self.x) and int(y) == int(self.y)
        return self._pixel(x, y, inside)
