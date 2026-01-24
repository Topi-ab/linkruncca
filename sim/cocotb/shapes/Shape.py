from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional, Tuple


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
