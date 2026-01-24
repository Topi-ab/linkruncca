import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from image_gen import TestImage
from image_queue import ImageQueueFeeder
from ellipse_collector import EllipseResultCollector

if os.getenv("COCOTB_DEBUG"):
    import debugpy

    debugpy.listen(("0.0.0.0", 5678))
    debugpy.wait_for_client()
    debugpy.breakpoint()


def _drive_collect(dut, in_label, x, y):
    dut.pix_in.in_label.value = int(in_label)
    dut.pix_in.x.value = int(x)
    dut.pix_in.y.value = int(y)
    dut.pix_in.has_red.value = 0
    dut.pix_in.has_green.value = 0
    dut.pix_in.has_blue.value = 0



async def _reset(dut, cycles=None):
    if cycles is None:
        cycles = int(os.getenv("LINKRUNCCA_X_SIZE", "200")) + 50
    dut.rst.value = 1
    dut.datavalid.value = 1
    _drive_collect(dut, 0, 0, 0)
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.datavalid.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def smoke_linkruncca(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await _reset(dut)

    img = TestImage(width=200, height=500)
    #img.add_circle(cx=40, cy=32, r=15, value=1)
    img.add_ellipse(cx=50, cy=100, rx=30, ry=25, angle_deg=30, value=1)
    #img.add_line(x0=0, y0=7, x1=15, y1=7, value=1, thickness=1)

    feeder = ImageQueueFeeder(dut, dut.clk)
    collector = EllipseResultCollector(dut, dut.clk)
    feeder.start()
    collector.start()
    await feeder.feed(img)
    await feeder.stop()
    await collector.stop()

    dut.datavalid.value = 0
    _drive_collect(dut, 0, 0, 0)
    for _ in range(5):
        await RisingEdge(dut.clk)
