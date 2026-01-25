import json
import os
from dataclasses import asdict

import cocotb

from image_queue import ImageQueueFeeder
from ellipse_collector import EllipseResultCollector
from dut_params import DutParams
from shapes.Circle import Circle
from shapes.Ellipse import Ellipse
from shapes.PixelShape import PixelShape
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
    height = 600

    db = ShapeDb()
    shapes = [
        Circle(cx=50.0, cy=60.0, r=15.0),
        Circle(cx=60.0, cy=70.0, r=15.0),
        Circle(cx=0.0, cy=50.0, r=40.0),

        Circle(cx=120.0, cy=200.0, r=15.0),

        Circle(cx=200.0, cy=300.0, r=15.0),

        PixelShape(100, 500),
        PixelShape(101, 501),
        PixelShape(100, 502),

        Ellipse(cx=50.0, cy=100.0, rx=30.0, ry=5.0),
        Line(x0=0.0, y0=1200-1, x1=30, y1=1230, width=3.0),
    ]
    for shape in shapes:
        db.add(shape)

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

    results_dir = os.getenv("COCOTB_RESULTS_DIR", "sim/cocotb/results")
    os.makedirs(results_dir, exist_ok=True)

    results_path = os.path.join(results_dir, "detections.json")
    with open(results_path, "w", encoding="utf-8") as handle:
        json.dump([asdict(r) for r in collector.results()], handle, indent=2)

    shapes_path = os.path.join(results_dir, "shapes.json")
    shapes_payload = {
        "meta": {"x_size": params.x_size, "height": height},
        "shapes": [],
    }
    for shape in shapes:
        shapes_payload["shapes"].append({"type": shape.kind, "params": shape.__dict__})
    with open(shapes_path, "w", encoding="utf-8") as handle:
        json.dump(shapes_payload, handle, indent=2)
