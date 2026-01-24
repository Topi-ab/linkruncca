import math
from dataclasses import dataclass
from typing import Optional, Tuple

from shapes.Shape import Pixel, Shape


@dataclass(frozen=True)
class Circle(Shape):
    cx: float
    cy: float
    r: float
    kind: str = "circle"

    def y_bounds(self) -> Tuple[int, int]:
        return (int(self.cy - self.r), int(self.cy + self.r))

    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        dy = y - self.cy
        if abs(dy) > self.r:
            return None
        dx = math.sqrt(max(self.r * self.r - dy * dy, 0.0))
        return (int(math.floor(self.cx - dx)), int(math.ceil(self.cx + dx)))

    def GetPixel(self, x: float, y: float) -> Pixel:
        dx = x - self.cx
        dy = y - self.cy
        inside = (dx * dx + dy * dy) <= (self.r * self.r)
        return self._pixel(x, y, inside)
