from typing import List, Optional

import cocotb
from cocotb.triggers import RisingEdge


class ResultCollector:
    def __init__(self, dut, clk, valid_name: str = "res_valid_out") -> None:
        self._dut = dut
        self._clk = clk
        self._valid_name = valid_name
        self._log = cocotb.log
        self._results: List[str] = []
        self._task = None
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

    def results(self) -> List[str]:
        return list(self._results)

    async def _runner(self) -> None:
        while True:
            await RisingEdge(self._clk)
            if int(getattr(self._dut, self._valid_name).value):
                payload = self._read_payload()
                self._results.append(payload)
                self._log.info("Result: %s", payload)

    def _read_payload(self) -> str:
        if hasattr(self._dut, "res_data_out"):
            return self._record_dump(self._dut.res_data_out)
        if hasattr(self._dut, "box_out"):
            return self._safe_value(self._dut.box_out)
        return "<no payload>"

    def _safe_value(self, handle) -> str:
        try:
            return str(handle.value)
        except AttributeError:
            return str(handle)

    def _format_value(self, handle) -> str:
        try:
            return str(int(handle.value))
        except Exception:
            try:
                return str(handle.value.integer)
            except Exception:
                return str(handle)

    def _record_dump(self, handle) -> str:
        fields = []
        for name in self._feature_fields:
            try:
                child = getattr(handle, name)
            except AttributeError:
                continue
            fields.append(f"{name}={self._format_value(child)}")
        if not fields:
            return self._safe_value(handle)
        return "{ " + ", ".join(fields) + " }"
