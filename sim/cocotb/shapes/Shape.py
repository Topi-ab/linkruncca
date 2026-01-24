from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional, Tuple
import math


@dataclass(frozen=True)
class Pixel:
    x: int
    y: int
    in_label: int
    has_red: int = 0
    has_green: int = 0
    has_blue: int = 0


class Shape(ABC):
    kind: str

    @abstractmethod
    def y_bounds(self) -> Tuple[int, int]:
        raise NotImplementedError

    @abstractmethod
    def x_bounds(self, y: float) -> Optional[Tuple[int, int]]:
        raise NotImplementedError

    @abstractmethod
    def GetPixel(self, x: float, y: float) -> Pixel:
        raise NotImplementedError

    def _pixel(
        self,
        x: float,
        y: float,
        in_label: bool,
        has_red: int = 0,
        has_green: int = 0,
        has_blue: int = 0,
    ) -> Pixel:
        return Pixel(
            x=int(x),
            y=int(y),
            in_label=1 if in_label else 0,
            has_red=has_red,
            has_green=has_green,
            has_blue=has_blue,
        )

    def intersects_ellipse(self, ellipse: dict) -> bool:
        cx = float(ellipse.get("cx", 0.0))
        cy = float(ellipse.get("cy", 0.0))
        major = float(ellipse.get("major", 0.0))
        minor = float(ellipse.get("minor", 0.0))
        theta = float(ellipse.get("theta", 0.0))

        a = major / 2.0
        b = minor / 2.0
        if a <= 0.0 or b <= 0.0:
            return False

        y0, y1 = self.y_bounds()
        ey0 = int(math.floor(cy - b))
        ey1 = int(math.ceil(cy + b))
        y_start = max(y0, ey0)
        y_end = min(y1, ey1)
        if y_end < y_start:
            return False

        rot = math.radians(theta)
        cos_r = math.cos(rot)
        sin_r = math.sin(rot)

        def ellipse_contains(x: float, y: float) -> bool:
            dx = x - cx
            dy = y - cy
            xp = dx * cos_r + dy * sin_r
            yp = -dx * sin_r + dy * cos_r
            return (xp * xp) / (a * a) + (yp * yp) / (b * b) <= 1.0

        for y in range(y_start, y_end + 1):
            xb = self.x_bounds(y)
            if xb is None:
                continue
            x0, x1 = xb
            for x in range(x0, x1 + 1):
                if self.GetPixel(x, y).in_label and ellipse_contains(x, y):
                    return True

        return False
