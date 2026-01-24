from dataclasses import dataclass
from typing import Optional, Tuple

from shapes.Shape import Pixel, Shape


@dataclass(frozen=True)
class Line(Shape):
    x0: float
    y0: float
    x1: float
    y1: float
    width: float = 1.0
    kind: str = "line"

    def y_bounds(self) -> Tuple[int, int]:
        return (int(min(self.y0, self.y1)), int(max(self.y0, self.y1)))

    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        y_min, y_max = self.y_bounds()
        if y < y_min or y > y_max:
            return None
        if self.y0 == self.y1:
            half = max(self.width, 1.0) / 2.0
            return (int(min(self.x0, self.x1) - half), int(max(self.x0, self.x1) + half))
        t = (y - self.y0) / (self.y1 - self.y0)
        if t < 0.0 or t > 1.0:
            return None
        x = self.x0 + t * (self.x1 - self.x0)
        half = max(self.width, 1.0) / 2.0
        return (int(x - half), int(x + half))

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
            half = max(self.width, 1.0) / 2.0
            inside = (
                abs(y - self.y0) <= half
                and min(self.x0, self.x1) - half <= x <= max(self.x0, self.x1) + half
            )
            return self._pixel(x, y, inside)
        half = max(self.width, 1.0) / 2.0
        # Distance from point to infinite line
        denom = (dx * dx + dy * dy) ** 0.5
        if denom == 0:
            return self._pixel(x, y, False)
        dist = abs(dy * x - dx * y + self.x1 * self.y0 - self.y1 * self.x0) / denom
        # Projection check within segment bounds
        t = ((x - self.x0) * dx + (y - self.y0) * dy) / (dx * dx + dy * dy)
        inside = (0.0 <= t <= 1.0) and (dist <= half)
        return self._pixel(x, y, inside)
