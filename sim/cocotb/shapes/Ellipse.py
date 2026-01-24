import math
from dataclasses import dataclass
from typing import Optional, Tuple

from shapes.Shape import Pixel, Shape


@dataclass(frozen=True)
class Ellipse(Shape):
    cx: float
    cy: float
    rx: float
    ry: float
    kind: str = "ellipse"

    def y_bounds(self) -> Tuple[int, int]:
        return (int(self.cy - self.ry), int(self.cy + self.ry))

    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        if self.ry <= 0:
            return None
        dy = (y - self.cy) / self.ry
        if abs(dy) > 1.0:
            return None
        dx = self.rx * math.sqrt(max(1.0 - dy * dy, 0.0))
        return (int(math.floor(self.cx - dx)), int(math.ceil(self.cx + dx)))

    def GetPixel(self, x: float, y: float) -> Pixel:
        if self.rx <= 0 or self.ry <= 0:
            return self._pixel(x, y, False)
        dx = (x - self.cx) / self.rx
        dy = (y - self.cy) / self.ry
        inside = (dx * dx + dy * dy) <= 1.0
        return self._pixel(x, y, inside)
