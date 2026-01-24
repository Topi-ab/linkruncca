import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


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

    dut.pix_in.neighbour.a.value = 0
    dut.pix_in.neighbour.b.value = 0
    dut.pix_in.neighbour.c.value = 0
    dut.pix_in.neighbour.d.value = 0
    dut.pix_in.neighbour.e.value = 0
    dut.pix_in.neighbour.a_orig.value = 0
    dut.pix_in.neighbour.b_orig.value = 0
    dut.pix_in.neighbour.c_orig.value = 0
    dut.pix_in.neighbour.d_orig.value = 0
    dut.pix_in.neighbour.e_orig.value = 0


async def _reset(dut, cycles=5):
    dut.rst.value = 1
    dut.datavalid.value = 0
    _drive_collect(dut, 0, 0, 0)
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def smoke_linkruncca(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await _reset(dut, cycles=5)

    for i in range(8):
        dut.datavalid.value = 1
        _drive_collect(dut, 1 if i % 2 == 0 else 0, i, 0)
        await RisingEdge(dut.clk)

    dut.datavalid.value = 0
    _drive_collect(dut, 0, 0, 0)
    for _ in range(5):
        await RisingEdge(dut.clk)
