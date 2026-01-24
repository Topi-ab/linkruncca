from typing import List

from shapes.Shape import Pixel, Shape
from shapes.PixelShape import PixelShape


class ShapeDb:
    def __init__(self) -> None:
        self._shapes: List[Shape] = []

    def add(self, shape: Shape) -> None:
        self._shapes.append(shape)

    def all(self) -> List[Shape]:
        return list(self._shapes)

    def active_at(self, y: int) -> List[Shape]:
        return [s for s in self._shapes if s.y_bounds()[0] <= y <= s.y_bounds()[1]]

    def pixel_at(self, x: int, y: int) -> Pixel:
        pixel = Pixel(x=x, y=y, in_label=0)
        for shape in self._shapes:
            y_min, y_max = shape.y_bounds()
            if y < y_min or y > y_max:
                continue
            candidate = shape.GetPixel(x, y)
            if candidate.in_label:
                pixel = candidate
        return pixel
