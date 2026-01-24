import math
from dataclasses import dataclass
from typing import Iterable, List, Tuple


@dataclass(frozen=True)
class _Shape:
    kind: str
    params: Tuple


class TestImage:
    def __init__(self, width: int, height: int, background: int = 0) -> None:
        self.width = int(width)
        self.height = int(height)
        self.background = int(background)
        self._shapes: List[_Shape] = []

    def add_circle(self, cx: float, cy: float, r: float, value: int = 1) -> None:
        self._shapes.append(_Shape("circle", (cx, cy, r, int(value))))

    def add_ellipse(
        self,
        cx: float,
        cy: float,
        rx: float,
        ry: float,
        angle_deg: float = 0.0,
        value: int = 1,
    ) -> None:
        self._shapes.append(_Shape("ellipse", (cx, cy, rx, ry, angle_deg, int(value))))

    def add_line(
        self,
        x0: float,
        y0: float,
        x1: float,
        y1: float,
        value: int = 1,
        thickness: int = 1,
    ) -> None:
        self._shapes.append(
            _Shape("line", (x0, y0, x1, y1, int(value), int(thickness)))
        )

    def clear(self) -> None:
        self._shapes.clear()

    def as_2d(self) -> List[List[int]]:
        img = [
            [self.background for _ in range(self.width)]
            for _ in range(self.height)
        ]
        for shape in self._shapes:
            if shape.kind == "circle":
                self._draw_circle(img, *shape.params)
            elif shape.kind == "ellipse":
                self._draw_ellipse(img, *shape.params)
            elif shape.kind == "line":
                self._draw_line(img, *shape.params)
        return img

    def as_flat(self) -> List[int]:
        img = self.as_2d()
        return [pix for row in img for pix in row]

    def iter_pixels(self) -> Iterable[Tuple[int, int, int]]:
        img = self.as_2d()
        for y, row in enumerate(img):
            for x, value in enumerate(row):
                yield x, y, value

    def _plot(self, img: List[List[int]], x: int, y: int, value: int) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            img[y][x] = value

    def _plot_thick(
        self, img: List[List[int]], x: int, y: int, value: int, thickness: int
    ) -> None:
        t = max(1, thickness)
        half = t // 2
        for yy in range(y - half, y - half + t):
            for xx in range(x - half, x - half + t):
                self._plot(img, xx, yy, value)

    def _draw_circle(
        self, img: List[List[int]], cx: float, cy: float, r: float, value: int
    ) -> None:
        if r <= 0:
            return
        r2 = r * r
        x_min = int(math.floor(cx - r))
        x_max = int(math.ceil(cx + r))
        y_min = int(math.floor(cy - r))
        y_max = int(math.ceil(cy + r))
        for y in range(y_min, y_max + 1):
            for x in range(x_min, x_max + 1):
                dx = x - cx
                dy = y - cy
                if dx * dx + dy * dy <= r2:
                    self._plot(img, x, y, value)

    def _draw_ellipse(
        self,
        img: List[List[int]],
        cx: float,
        cy: float,
        rx: float,
        ry: float,
        angle_deg: float,
        value: int,
    ) -> None:
        if rx <= 0 or ry <= 0:
            return
        angle = math.radians(angle_deg)
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        x_min = int(math.floor(cx - rx))
        x_max = int(math.ceil(cx + rx))
        y_min = int(math.floor(cy - ry))
        y_max = int(math.ceil(cy + ry))
        rx2 = rx * rx
        ry2 = ry * ry
        for y in range(y_min, y_max + 1):
            for x in range(x_min, x_max + 1):
                dx = x - cx
                dy = y - cy
                xp = dx * cos_a + dy * sin_a
                yp = -dx * sin_a + dy * cos_a
                if (xp * xp) / rx2 + (yp * yp) / ry2 <= 1.0:
                    self._plot(img, x, y, value)

    def _draw_line(
        self,
        img: List[List[int]],
        x0: float,
        y0: float,
        x1: float,
        y1: float,
        value: int,
        thickness: int,
    ) -> None:
        x0i = int(round(x0))
        y0i = int(round(y0))
        x1i = int(round(x1))
        y1i = int(round(y1))
        dx = abs(x1i - x0i)
        dy = -abs(y1i - y0i)
        sx = 1 if x0i < x1i else -1
        sy = 1 if y0i < y1i else -1
        err = dx + dy
        x = x0i
        y = y0i
        while True:
            self._plot_thick(img, x, y, value, thickness)
            if x == x1i and y == y1i:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x += sx
            if e2 <= dx:
                err += dx
                y += sy
