#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import os
import signal
import shlex
from pathlib import Path
from typing import Dict, List

from cocotb_tools.runner import get_runner

from shapes.Circle import Circle
from shapes.Ellipse import Ellipse
from shapes.Line import Line
from shapes.PixelShape import PixelShape


def _split_env(name: str) -> List[str]:
    value = os.getenv(name)
    if not value:
        return []
    return shlex.split(value)


def _env_int(name: str) -> int | None:
    value = os.getenv(name)
    if value is None or value == "":
        return None
    return int(value, 0)


def _default_sources(root: Path, hdl_toplevel: str) -> List[Path]:
    src_vhdl = root / "src" / "vhdl"
    sim_vhdl = root / "sim" / "vhdl"

    pkg_name = os.getenv(
        "LINKRUNCCA_PKG",
        "vhdl_linkruncca_pkg_ellipses_linescan.vhdl",
    )

    sources = [
        src_vhdl / "vhdl_linkruncca_util_pkg.vhdl",
        sim_vhdl / pkg_name,
        sim_vhdl / "ellipse_generator_pkg.vhdl",
        src_vhdl / "vhdl_table_ram_add.vhdl",
        src_vhdl / "vhdl_table_ram_data.vhdl",
        src_vhdl / "vhdl_table_reader.vhdl",
        src_vhdl / "vhdl_window.vhdl",
        src_vhdl / "vhdl_holes_filler.vhdl",
        src_vhdl / "vhdl_equivalence_resolver.vhdl",
        src_vhdl / "vhdl_feature_accumulator.vhdl",
        src_vhdl / "vhdl_row_buf.vhdl",
        #src_vhdl / "feature_precalc.vhdl",
        src_vhdl / "vhdl_linkruncca.vhdl",
    ]

    include_tb = os.getenv("INCLUDE_TB", "").lower() in {"1", "true", "yes"}
    if include_tb or hdl_toplevel == "tb_linkruncca":
        sources.append(sim_vhdl / "tb_linkruncca.vhdl")

    return sources


def _default_parameters() -> Dict[str, int]:
    params: Dict[str, int] = {}
    imwidth = _env_int("LINKRUNCCA_IMWIDTH")
    imheight = _env_int("LINKRUNCCA_IMHEIGHT")
    if imwidth is not None:
        params["imwidth"] = imwidth
    if imheight is not None:
        params["imheight"] = imheight
    return params


def run() -> None:
    root = Path(__file__).resolve().parents[2]
    sim = os.getenv("SIM", "ghdl").lower()
    hdl_toplevel = os.getenv("TOPLEVEL", "vhdl_linkruncca")
    test_module = os.getenv("COCOTB_TEST_MODULES") or os.getenv(
        "TEST_MODULE", "test_linkruncca"
    )

    build_args: List[str] = []
    test_args: List[str] = []
    if sim == "ghdl":
        ghdl_std = os.getenv("GHDL_STD", "08")
        std_arg = f"--std={ghdl_std}"
        build_args = [std_arg, *_split_env("GHDL_BUILD_ARGS")]
        test_args = [std_arg, *_split_env("GHDL_RUN_ARGS")]
    elif sim == "nvc":
        nvc_std = os.getenv("NVC_STD", "08")
        std_arg = f"--std={nvc_std}"
        build_args = [std_arg, *_split_env("NVC_BUILD_ARGS")]
        test_args = [*_split_env("NVC_RUN_ARGS")]
        if not any(arg.startswith("--ieee-warnings") for arg in build_args):
            build_args.append("--ieee-warnings=off")

    sources = _default_sources(root, hdl_toplevel)
    build_dir = Path(os.getenv("SIM_BUILD_DIR", root / "sim" / "cocotb" / "sim_build"))

    runner = get_runner(sim)
    runner.build(
        vhdl_sources=sources,
        hdl_toplevel=hdl_toplevel,
        parameters=_default_parameters(),
        build_args=build_args,
        build_dir=build_dir,
        always=True,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="vhdl",
        test_module=test_module,
        test_args=test_args,
        build_dir=build_dir,
        waves=True,
    )

    detections = list(Path(build_dir).rglob("detections.json"))
    if detections:
        try:
            import matplotlib.pyplot as plt
            from matplotlib.patches import Rectangle
        except Exception as exc:
            raise RuntimeError("matplotlib is required for plotting detections") from exc

        with open(detections[0], "r", encoding="utf-8") as handle:
            items = json.load(handle)

        shapes_files = list(Path(build_dir).rglob("shapes.json"))
        shapes = []
        shape_entries = []
        x_size = None
        if shapes_files:
            with open(shapes_files[0], "r", encoding="utf-8") as handle:
                payload = json.load(handle)
            shape_items = payload.get("shapes", [])
            meta = payload.get("meta", {})
            if "x_size" in meta:
                x_size = float(meta["x_size"])
            for entry in shape_items:
                shape_type = entry.get("type")
                params = dict(entry.get("params", {}))
                params.pop("kind", None)
                shape_entries.append(entry)
                if shape_type == "circle":
                    shapes.append(Circle(**params))
                elif shape_type == "ellipse":
                    shapes.append(Ellipse(**params))
                elif shape_type == "line":
                    shapes.append(Line(**params))
                elif shape_type == "pixel":
                    shapes.append(PixelShape(**params))

        if x_size is None:
            x_size_env = os.getenv("LINKRUNCCA_X_SIZE")
            x_size = float(x_size_env) if x_size_env else None

        for idx, item in enumerate(items):
            cx = float(item.get("cx", 0.0))
            cy = float(item.get("cy", 0.0))
            major = float(item.get("major", 0.0))
            minor = float(item.get("minor", 0.0))
            theta = float(item.get("theta", 0.0))

            a = major / 2.0
            b = minor / 2.0
            angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
            x = [a * math.cos(t) for t in angles]
            y = [b * math.sin(t) for t in angles]

            rot = math.radians(theta)
            cos_r = math.cos(rot)
            sin_r = math.sin(rot)
            xr = [cx + xi * cos_r - yi * sin_r for xi, yi in zip(x, y)]
            yr = [cy + xi * sin_r + yi * cos_r for xi, yi in zip(x, y)]

            plt.figure()
            plt.title(f"Detection {idx}")
            plt.axis("equal")
            plt.gca().invert_yaxis()
            plt.xlim(min(xr) - 2.0, max(xr) + 2.0)
            plt.ylim(max(yr) + 2.0, min(yr) - 2.0)
            plt.grid(True, linestyle="--", alpha=0.3)

            if shapes:
                overlaps = [s.kind for s in shapes if s.intersects_ellipse(item)]
                if overlaps:
                    print(f"Detection {idx} overlaps shapes: {', '.join(overlaps)}")
                else:
                    print(f"Detection {idx} overlaps shapes: none")

                colors = [
                    "tab:blue",
                    "tab:orange",
                    "tab:green",
                    "tab:red",
                    "tab:purple",
                    "tab:brown",
                    "tab:pink",
                    "tab:gray",
                    "tab:olive",
                    "tab:cyan",
                ]
                for shape_idx, (shape, entry) in enumerate(zip(shapes, shape_entries)):
                    if not shape.intersects_ellipse(item):
                        continue
                    color = colors[shape_idx % len(colors)]
                    params = entry.get("params", {})
                    shape_type = entry.get("type")
                    if shape_type == "circle":
                        cx_s = params.get("cx", 0.0)
                        cy_s = params.get("cy", 0.0)
                        r = params.get("r", 0.0)
                        angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
                        xs = [cx_s + r * math.cos(t) for t in angles]
                        ys = [cy_s + r * math.sin(t) for t in angles]
                        plt.fill(xs, ys, color=color, alpha=0.35, zorder=1)
                    elif shape_type == "ellipse":
                        cx_s = params.get("cx", 0.0)
                        cy_s = params.get("cy", 0.0)
                        rx = params.get("rx", 0.0)
                        ry = params.get("ry", 0.0)
                        angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
                        xs = [cx_s + rx * math.cos(t) for t in angles]
                        ys = [cy_s + ry * math.sin(t) for t in angles]
                        plt.fill(xs, ys, color=color, alpha=0.35, zorder=1)
                    elif shape_type == "line":
                        x0 = params.get("x0", 0.0)
                        y0 = params.get("y0", 0.0)
                        x1 = params.get("x1", 0.0)
                        y1 = params.get("y1", 0.0)
                        plt.plot([x0, x1], [y0, y1], color=color, linewidth=2, zorder=1)
                    elif shape_type == "pixel":
                        px = params.get("x", 0.0)
                        py = params.get("y", 0.0)
                        plt.gca().add_patch(
                            Rectangle(
                                (px - 0.5, py - 0.5),
                                1.0,
                                1.0,
                                facecolor=color,
                                edgecolor=color,
                                linewidth=0.0,
                                zorder=2,
                            )
                        )

            plt.plot(xr, yr, color="black", zorder=3)
            if x_size is not None and xr:
                x_min = min(xr)
                x_max = max(xr)
                if x_min <= 0.0:
                    print(f"Detection {idx} left edge hit: x_min={x_min:.3f}")
                    plt.axvline(0.0, color="black", linestyle=":")
                if x_max >= x_size:
                    print(f"Detection {idx} right edge hit: x_max={x_max:.3f} x_size={x_size:.3f}")
                    plt.axvline(x_size, color="black", linestyle=":")

        def _sigint_handler(_signum, _frame):
            plt.close("all")
            raise SystemExit(130)

        old_handler = signal.signal(signal.SIGINT, _sigint_handler)
        try:
            plt.show(block=False)
            while True:
                if not plt.get_fignums():
                    break
                plt.pause(0.1)
        except KeyboardInterrupt:
            plt.close("all")
        finally:
            signal.signal(signal.SIGINT, old_handler)


if __name__ == "__main__":
    run()
