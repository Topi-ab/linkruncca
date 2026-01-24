import math
import os
from dataclasses import dataclass
from typing import Dict, List

import cocotb
from cocotb.triggers import RisingEdge


@dataclass
class ResolvedEllipse:
    cx: float = 0.0
    cy: float = 0.0
    major: float = 0.0
    minor: float = 0.0
    theta: float = 0.0
    pixels: float = 0.0
    perimeter: float = 0.0
    geom_case: int = 0
    u20: float = 0.0
    u02: float = 0.0
    u11: float = 0.0
    l_left: float = 0.0
    l_right: float = 0.0
    l1: float = 0.0
    l2: float = 0.0
    x_left: float = 0.0
    x_right: float = 0.0
    y_top: float = 0.0
    y_bottom: float = 0.0
    sum_x: float = 0.0
    sum_y: float = 0.0
    sum_xx: float = 0.0
    sum_yy: float = 0.0
    sum_xy: float = 0.0
    y_top_seg0: float = 0.0
    y_top_seg1: float = 0.0
    y_bottom_seg0: float = 0.0
    y_bottom_seg1: float = 0.0
    ylow2_sum: float = 0.0
    xylow_sum: float = 0.0
    x_seg0_sum: float = 0.0
    x_seg1_sum: float = 0.0
    ylow_seg0_sum: float = 0.0
    ylow_seg1_sum: float = 0.0
    n_seg0_sum: float = 0.0
    n_seg1_sum: float = 0.0


class EllipseResultCollector:
    def __init__(
        self,
        dut,
        clk,
        valid_name: str = "res_valid_out",
        y_bits: int | None = None,
        y_low_size: int | None = None,
        y_size: int | None = None,
    ) -> None:
        self._dut = dut
        self._clk = clk
        self._valid_name = valid_name
        self._log = cocotb.log
        self._results: List[ResolvedEllipse] = []
        self._task = None

        if y_bits is None:
            env_bits = os.getenv("LINKRUNCCA_Y_BITS")
            y_bits = int(env_bits) if env_bits else 10

        self._y_low_size = (
            int(y_low_size) if y_low_size is not None else 2 ** (y_bits - 1)
        )
        self._y_size = int(y_size) if y_size is not None else 2**y_bits

        self._feature_fields = [
            "x_left",
            "x_right",
            "y_top_seg0",
            "y_top_seg1",
            "y_bottom_seg0",
            "y_bottom_seg1",
            "x2_sum",
            "ylow2_sum",
            "xylow_sum",
            "x_seg0_sum",
            "x_seg1_sum",
            "ylow_seg0_sum",
            "ylow_seg1_sum",
            "n_seg0_sum",
            "n_seg1_sum",
            "edge_orthogonal_seg0_sum",
            "edge_orthogonal_seg1_sum",
            "edge_diagonal_seg0_sum",
            "edge_diagonal_seg1_sum",
        ]

    def start(self) -> None:
        if self._task is None:
            self._task = cocotb.start_soon(self._runner())

    async def stop(self) -> None:
        if self._task is None:
            return
        self._task.cancel()
        self._task = None

    def results(self) -> List[ResolvedEllipse]:
        return list(self._results)

    async def _runner(self) -> None:
        while True:
            await RisingEdge(self._clk)
            if int(getattr(self._dut, self._valid_name).value):
                feature = self._read_feature(self._dut.res_data_out)
                resolved = resolve_ellipse(feature, self._y_low_size, self._y_size)
                self._results.append(resolved)
                self._log.info("Resolved: %s", resolved)

    def _read_feature(self, handle) -> Dict[str, int]:
        feature: Dict[str, int] = {}
        for name in self._feature_fields:
            try:
                child = getattr(handle, name)
            except AttributeError:
                feature[name] = 0
                continue
            try:
                feature[name] = int(child.value)
            except Exception:
                feature[name] = 0
        return feature


def resolve_ellipse(
    a: Dict[str, int], y_low_size: int, y_size: int
) -> ResolvedEllipse:
    r = ResolvedEllipse()
    pixels = float(a["n_seg0_sum"] + a["n_seg1_sum"])
    if pixels == 0.0:
        return r

    sum_x = float(a["x_seg0_sum"] + a["x_seg1_sum"])
    sum_xx = float(a["x2_sum"])

    geom_case = 0
    if a["n_seg0_sum"] != 0 and a["n_seg1_sum"] == 0:
        geom_case = 1
        r.y_top = float(a["y_top_seg0"])
        r.y_bottom = float(a["y_bottom_seg0"])
    elif a["n_seg0_sum"] == 0 and a["n_seg1_sum"] != 0:
        geom_case = 2
        r.y_top = float(a["y_top_seg1"]) + float(y_low_size)
        r.y_bottom = float(a["y_bottom_seg1"]) + float(y_low_size)
    else:
        if a["y_top_seg0"] != 0 and a["y_top_seg1"] == 0:
            geom_case = 3
            r.y_top = float(a["y_top_seg0"])
            r.y_bottom = float(a["y_bottom_seg1"]) + float(y_low_size)
        elif a["y_top_seg0"] == 0 and a["y_top_seg1"] != 0:
            geom_case = 4
            r.y_top = float(a["y_top_seg1"]) - float(y_low_size)
            r.y_bottom = float(a["y_bottom_seg0"])

    sum_y = 0.0
    sum_yy = 0.0
    sum_xy = 0.0
    if geom_case in (1, 2, 3):
        sum_y = float(a["ylow_seg0_sum"] + a["ylow_seg1_sum"]) + float(
            y_low_size
        ) * float(a["n_seg1_sum"])
        sum_yy = (
            float(a["ylow2_sum"])
            + float(y_size) * float(a["ylow_seg1_sum"])
            + float(y_low_size) ** 2 * float(a["n_seg1_sum"])
        )
        sum_xy = float(a["xylow_sum"]) + float(y_low_size) * float(a["x_seg1_sum"])
    elif geom_case == 4:
        sum_y = float(a["ylow_seg0_sum"] + a["ylow_seg1_sum"]) - float(
            y_low_size
        ) * float(a["n_seg1_sum"])
        sum_yy = (
            float(a["ylow2_sum"])
            - float(y_size) * float(a["ylow_seg1_sum"])
            + float(y_low_size) ** 2 * float(a["n_seg1_sum"])
        )
        sum_xy = float(a["xylow_sum"]) - float(y_low_size) * float(a["x_seg1_sum"])

    x_mean = sum_x / pixels
    y_mean = sum_y / pixels
    u20 = sum_xx / pixels - x_mean**2
    u02 = sum_yy / pixels - y_mean**2
    u11 = sum_xy / pixels - x_mean * y_mean
    l_left = (u20 + u02) / 2.0
    l_right = math.sqrt(((u20 - u02) / 2.0) ** 2 + u11**2)
    l1 = l_left + l_right
    l2 = l_left - l_right

    r.pixels = pixels
    r.cx = x_mean
    r.cy = y_mean
    r.major = 4.0 * math.sqrt(max(l1, 0.0))
    r.minor = 4.0 * math.sqrt(max(l2, 0.0))
    r.theta = 0.5 * math.atan2(2.0 * u11, u20 - u02) / math.pi * 180.0

    edge_orthogonal = float(a["edge_orthogonal_seg0_sum"] + a["edge_orthogonal_seg1_sum"])
    edge_diagonal = float(a["edge_diagonal_seg0_sum"] + a["edge_diagonal_seg1_sum"])
    r.perimeter = math.pi / 4.0 * (edge_orthogonal + 1.0 / math.sqrt(2.0) * edge_diagonal)

    r.geom_case = geom_case
    r.u20 = u20
    r.u02 = u02
    r.u11 = u11
    r.l_left = l_left
    r.l_right = l_right
    r.l1 = l1
    r.l2 = l2

    r.x_left = float(a["x_left"])
    r.x_right = float(a["x_right"])

    r.sum_x = sum_x
    r.sum_y = sum_y
    r.sum_xx = sum_xx
    r.sum_yy = sum_yy
    r.sum_xy = sum_xy

    r.y_top_seg0 = float(a["y_top_seg0"])
    r.y_top_seg1 = float(a["y_top_seg1"])
    r.y_bottom_seg0 = float(a["y_bottom_seg0"])
    r.y_bottom_seg1 = float(a["y_bottom_seg1"])
    r.ylow2_sum = float(a["ylow2_sum"])
    r.xylow_sum = float(a["xylow_sum"])
    r.x_seg0_sum = float(a["x_seg0_sum"])
    r.x_seg1_sum = float(a["x_seg1_sum"])
    r.ylow_seg0_sum = float(a["ylow_seg0_sum"])
    r.ylow_seg1_sum = float(a["ylow_seg1_sum"])
    r.n_seg0_sum = float(a["n_seg0_sum"])
    r.n_seg1_sum = float(a["n_seg1_sum"])

    return r
