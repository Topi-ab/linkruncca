from dataclasses import dataclass
from typing import Optional, Tuple

from shapes.Shape import Pixel, Shape


@dataclass(frozen=True)
class Line(Shape):
    x0: float
    y0: float
    x1: float
    y1: float
    kind: str = "line"

    def y_bounds(self) -> Tuple[int, int]:
        return (int(min(self.y0, self.y1)), int(max(self.y0, self.y1)))

    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        y_min, y_max = self.y_bounds()
        if y < y_min or y > y_max:
            return None
        if self.y0 == self.y1:
            return (int(min(self.x0, self.x1)), int(max(self.x0, self.x1)))
        t = (y - self.y0) / (self.y1 - self.y0)
        if t < 0.0 or t > 1.0:
            return None
        x = self.x0 + t * (self.x1 - self.x0)
        return (int(x), int(x))

    def GetPixel(self, x: float, y: float) -> Pixel:
        y_min, y_max = self.y_bounds()
        if y < y_min or y > y_max:
            return self._pixel(x, y, False)
        dx = self.x1 - self.x0
        dy = self.y1 - self.y0
        if dx == 0 and dy == 0:
            inside = x == self.x0 and y == self.y0
            return self._pixel(x, y, inside)
        if dy == 0:
            inside = y == self.y0 and min(self.x0, self.x1) <= x <= max(self.x0, self.x1)
            return self._pixel(x, y, inside)
        t = (y - self.y0) / dy
        x_at_y = self.x0 + t * dx
        inside = abs(x - x_at_y) < 1e-9
        return self._pixel(x, y, inside)
