from typing import Iterable, List, Optional, Sequence, Tuple

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge

Pixel = Tuple[int, int, int]


def drive_linkruncca_record(
    dut, x: int, y: int, value: int, valid: bool = True
) -> None:
    try:
        dut.datavalid.value = int(bool(valid))
        dut.pix_in.in_label.value = int(value)
        dut.pix_in.x.value = int(x)
        dut.pix_in.y.value = int(y)
        dut.pix_in.has_red.value = 0
        dut.pix_in.has_green.value = 0
        dut.pix_in.has_blue.value = 0
    except AttributeError as exc:
        raise RuntimeError(
            "DUT does not expose pix_in/datavalid. Provide a custom drive_pixel "
            "function or use an adapter with flat ports."
        ) from exc


class ImageQueueFeeder:
    def __init__(
        self,
        dut,
        clk,
        drive_pixel=drive_linkruncca_record,
        idle_cycles: int = 1,
    ) -> None:
        self._dut = dut
        self._clk = clk
        self._drive_pixel = drive_pixel
        self._idle_cycles = int(idle_cycles)
        self._queue: Queue = Queue()
        self._task = None
        self._clock_task = None

    def start_clock(self, period: int = 10, unit: str = "ns") -> None:
        if self._clock_task is None:
            clock = Clock(self._clk, period, unit=unit)
            self._clock_task = cocotb.start_soon(clock.start())

    def stop_clock(self) -> None:
        if self._clock_task is not None:
            self._clock_task.cancel()
            self._clock_task = None

    def start(self) -> None:
        if self._task is None:
            self._task = cocotb.start_soon(self._runner())

    async def stop(self) -> None:
        await self._queue.put(None)
        if self._task is not None:
            await self._task

    async def enqueue(
        self,
        image: object,
        width: Optional[int] = None,
        height: Optional[int] = None,
    ) -> None:
        pixels = self._normalize_image(image, width=width, height=height)
        await self._queue.put(pixels)

    async def feed(
        self,
        image: object,
        width: Optional[int] = None,
        height: Optional[int] = None,
    ) -> None:
        await self.enqueue(image, width=width, height=height)

    async def reset(self, cycles: int) -> None:
        self._dut.rst.value = 1
        self._dut.datavalid.value = 1
        self._drive_pixel(self._dut, 0, 0, 0, True)
        for _ in range(int(cycles)):
            await RisingEdge(self._clk)
        self._dut.rst.value = 0
        self._dut.datavalid.value = 0
        await RisingEdge(self._clk)

    async def idle(self, cycles: int) -> None:
        for _ in range(int(cycles)):
            self._drive_pixel(self._dut, 0, 0, 0, False)
            await RisingEdge(self._clk)

    async def _runner(self) -> None:
        while True:
            pixels = await self._queue.get()
            if pixels is None:
                break
            for x, y, value in pixels:
                self._drive_pixel(self._dut, x, y, value, True)
                await RisingEdge(self._clk)
            for _ in range(self._idle_cycles):
                self._drive_pixel(self._dut, 0, 0, 0, False)
                await RisingEdge(self._clk)

    def _normalize_image(
        self, image: object, width: Optional[int], height: Optional[int]
    ) -> List[Pixel]:
        if hasattr(image, "iter_pixels"):
            return list(image.iter_pixels())

        if isinstance(image, Sequence) and image:
            first = image[0]
            if isinstance(first, (tuple, list)) and len(first) == 3:
                return [(int(x), int(y), int(v)) for x, y, v in image]  # type: ignore[misc]
            if isinstance(first, (tuple, list)):
                pixels: List[Pixel] = []
                for y, row in enumerate(image):  # type: ignore[misc]
                    for x, value in enumerate(row):
                        pixels.append((x, y, int(value)))
                return pixels

        if isinstance(image, Sequence):
            if width is None or height is None:
                raise ValueError("width and height are required for flat images")
            if len(image) != width * height:
                raise ValueError("flat image length does not match width*height")
            pixels = []
            for idx, value in enumerate(image):
                x = idx % width
                y = idx // width
                pixels.append((x, y, int(value)))
            return pixels

        if isinstance(image, Iterable):
            return [(int(x), int(y), int(v)) for x, y, v in image]  # type: ignore[misc]

        raise TypeError("Unsupported image format for enqueue()")
