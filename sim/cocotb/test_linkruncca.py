import os

import cocotb

from image_queue import ImageQueueFeeder
from ellipse_collector import EllipseResultCollector
from dut_params import DutParams
from shapes.Circle import Circle
from shapes.Ellipse import Ellipse
from shapes.Line import Line
from shapes.ShapeDb import ShapeDb

if os.getenv("COCOTB_DEBUG"):
    import debugpy

    debugpy.listen(("0.0.0.0", 5678))
    debugpy.wait_for_client()
    #debugpy.breakpoint()


@cocotb.test()
async def smoke_linkruncca(dut):
    feeder = ImageQueueFeeder(dut, dut.clk)
    feeder.start_clock(period=1, unit="ns")
    params = DutParams.from_dut(dut)
    await feeder.reset(cycles=params.x_size + 5)

    width = params.x_size
    height = 500

    db = ShapeDb()
    db.add(Circle(cx=40.0, cy=32.0, r=15.0))
    db.add(Ellipse(cx=50.0, cy=100.0, rx=30.0, ry=25.0))
    #db.add(Line(x0=0.0, y0=height - 1, x1=width - 1, y1=height - 1))

    collector = EllipseResultCollector(dut, dut.clk)
    feeder.start()
    collector.start()
    for y in range(height):
        line_pixels = []
        for x in range(width):
            pix = db.pixel_at(x, y)
            line_pixels.append((pix.x, params.wrap_y(pix.y), pix.in_label))
        await feeder.feed(line_pixels)
    await feeder.stop()
    await collector.stop()

    dut.datavalid.value = 0
    await feeder.idle(5)
