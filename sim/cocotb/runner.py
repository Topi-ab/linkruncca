#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import os
import signal
import shlex
import warnings
from pathlib import Path
from typing import Dict, List

from cocotb_tools.runner import get_runner

from shapes.Circle import Circle
from shapes.Ellipse import Ellipse
from shapes.Line import Line
from shapes.PixelShape import PixelShape
from shapes.ShapeDb import ShapeDb


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


def _env_bool(name: str, default: bool = True) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


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
        show_plots = not _env_bool("DISABLE_PLOT", False)
        try:
            import numpy as np
        except Exception as exc:
            raise RuntimeError("numpy is required for pixel map generation") from exc
        try:
            import cv2
        except Exception as exc:
            raise RuntimeError("opencv-python is required for perimeter calculation") from exc

        if show_plots:
            try:
                import matplotlib.pyplot as plt
                from matplotlib.patches import Rectangle
            except Exception as exc:
                raise RuntimeError("matplotlib is required for plotting detections") from exc

            backend = (plt.get_backend() or "").lower()
            noninteractive_backends = {
                "agg",
                "cairo",
                "pdf",
                "pgf",
                "ps",
                "svg",
                "template",
            }
            if backend in noninteractive_backends:
                warnings.warn(
                    (
                        f"Matplotlib backend '{plt.get_backend()}' is non-interactive; "
                        "disabling plots. Set DISABLE_PLOT=1 to silence this warning "
                        "or configure an interactive backend/X11."
                    ),
                    UserWarning,
                )
                show_plots = False

        with open(detections[0], "r", encoding="utf-8") as handle:
            items = json.load(handle)

        shapes_files = list(Path(build_dir).rglob("shapes.json"))
        shapes = []
        shape_entries = []
        x_size = None
        height = None
        if shapes_files:
            with open(shapes_files[0], "r", encoding="utf-8") as handle:
                payload = json.load(handle)
            shape_items = payload.get("shapes", [])
            meta = payload.get("meta", {})
            if "x_size" in meta:
                x_size = float(meta["x_size"])
            if "height" in meta:
                height = int(meta["height"])
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
        if height is None:
            height_env = os.getenv("LINKRUNCCA_HEIGHT")
            height = int(height_env) if height_env else None

        shape_db = ShapeDb()
        for shape in shapes:
            shape_db.add(shape)

        if shapes and (x_size is None or height is None):
            raise RuntimeError(
                "shapes.json meta x_size and height (or LINKRUNCCA_HEIGHT) "
                "are required for ref pixel map generation"
            )

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

            x_plot_min = math.floor(min(xr) - 2.0)
            x_plot_max = math.ceil(max(xr) + 2.0)
            y_plot_min = math.floor(min(yr) - 2.0)
            y_plot_max = math.ceil(max(yr) + 2.0)

            if show_plots:
                fig, (ax, ax_text) = plt.subplots(
                    1,
                    2,
                    gridspec_kw={"width_ratios": [3, 2]},
                    constrained_layout=True,
                )
                ax.set_title(f"Detection {idx}")
                ax.set_aspect("equal", adjustable="box")
                ax.invert_yaxis()
                ax.set_xlim(x_plot_min, x_plot_max)
                ax.set_ylim(y_plot_max, y_plot_min)
                ax.grid(True, linestyle="--", alpha=0.3)
                ax_text.axis("off")

            if shapes:
                overlapping_shapes = []
                overlap_kinds = []
                overlap_flags = []
                for shape, entry in zip(shapes, shape_entries):
                    hit = shape.intersects_ellipse(item)
                    overlap_flags.append(hit)
                    if hit:
                        overlapping_shapes.append(shape)
                        overlap_kinds.append(shape)
                if overlap_kinds:
                    print(
                        "Detection "
                        f"{idx} overlaps shapes: {', '.join(s.kind for s in overlap_kinds)}"
                    )
                else:
                    print(f"Detection {idx} overlaps shapes: none")

                if show_plots and x_size is not None and overlap_flags:
                    x_min = x_plot_min
                    x_max = x_plot_max
                    y_min = y_plot_min
                    y_max = y_plot_max
                    for entry, hit in zip(shape_entries, overlap_flags):
                        if not hit:
                            continue
                        params = entry.get("params", {})
                        shape_type = entry.get("type")
                        if shape_type == "circle":
                            cx_s = float(params.get("cx", 0.0))
                            cy_s = float(params.get("cy", 0.0))
                            r = float(params.get("r", 0.0))
                            sx0 = cx_s - r
                            sx1 = cx_s + r
                            sy0 = cy_s - r
                            sy1 = cy_s + r
                        elif shape_type == "ellipse":
                            cx_s = float(params.get("cx", 0.0))
                            cy_s = float(params.get("cy", 0.0))
                            rx = float(params.get("rx", 0.0))
                            ry = float(params.get("ry", 0.0))
                            sx0 = cx_s - rx
                            sx1 = cx_s + rx
                            sy0 = cy_s - ry
                            sy1 = cy_s + ry
                        elif shape_type == "line":
                            x0 = float(params.get("x0", 0.0))
                            y0 = float(params.get("y0", 0.0))
                            x1 = float(params.get("x1", 0.0))
                            y1 = float(params.get("y1", 0.0))
                            width = float(params.get("width", 0.0))
                            half = width / 2.0
                            sx0 = min(x0, x1) - half
                            sx1 = max(x0, x1) + half
                            sy0 = min(y0, y1) - half
                            sy1 = max(y0, y1) + half
                        elif shape_type == "pixel":
                            px = float(params.get("x", 0.0))
                            py = float(params.get("y", 0.0))
                            sx0 = px - 0.5
                            sx1 = px + 0.5
                            sy0 = py - 0.5
                            sy1 = py + 0.5
                        else:
                            continue
                        if sx1 < 0.0 or sx0 > x_size:
                            continue
                        sx0 = max(sx0, 0.0)
                        sx1 = min(sx1, x_size)
                        x_min = min(x_min, math.floor(sx0) - 2)
                        x_max = max(x_max, math.ceil(sx1) + 2)
                        y_min = min(y_min, math.floor(sy0) - 2)
                        y_max = max(y_max, math.ceil(sy1) + 2)
                    x_plot_min = x_min
                    x_plot_max = x_max
                    y_plot_min = y_min
                    y_plot_max = y_max
                    ax.set_xlim(x_plot_min, x_plot_max)
                    ax.set_ylim(y_plot_max, y_plot_min)

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
                plot_idx = 0
                for shape, entry, hit in zip(shapes, shape_entries, overlap_flags):
                    if not hit:
                        continue
                    color = colors[plot_idx % len(colors)]
                    plot_idx += 1
                    params = entry.get("params", {})
                    shape_type = entry.get("type")
                    if shape_type == "circle":
                        cx_s = params.get("cx", 0.0)
                        cy_s = params.get("cy", 0.0)
                        r = params.get("r", 0.0)
                        angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
                        xs = [cx_s + r * math.cos(t) for t in angles]
                        ys = [cy_s + r * math.sin(t) for t in angles]
                        if show_plots:
                            ax.fill(xs, ys, color=color, alpha=0.35, zorder=1)
                    elif shape_type == "ellipse":
                        cx_s = params.get("cx", 0.0)
                        cy_s = params.get("cy", 0.0)
                        rx = params.get("rx", 0.0)
                        ry = params.get("ry", 0.0)
                        angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
                        xs = [cx_s + rx * math.cos(t) for t in angles]
                        ys = [cy_s + ry * math.sin(t) for t in angles]
                        if show_plots:
                            ax.fill(xs, ys, color=color, alpha=0.35, zorder=1)
                    elif shape_type == "line":
                        x0 = params.get("x0", 0.0)
                        y0 = params.get("y0", 0.0)
                        x1 = params.get("x1", 0.0)
                        y1 = params.get("y1", 0.0)
                        if show_plots:
                            ax.plot(
                                [x0, x1],
                                [y0, y1],
                                color=color,
                                linewidth=2,
                                zorder=1,
                            )
                    elif shape_type == "pixel":
                        px = params.get("x", 0.0)
                        py = params.get("y", 0.0)
                        if show_plots:
                            ax.add_patch(
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

                detected_pixels = int(item.get("pixels", 0))
                detected_perimeter = float(item.get("perimeter", 0.0))
                ref_pixels = 0
                ref_perimeter = 0.0
                if overlapping_shapes and x_size is not None and height is not None:
                    overlap_db = ShapeDb()
                    for shape in overlapping_shapes:
                        overlap_db.add(shape)
                    width = int(x_size)
                    if width > 0 and height > 0:
                        ref_bitmap = np.zeros((height, width), dtype=np.uint8)
                        for y in range(height):
                            for x in range(width):
                                if overlap_db.pixel_at(x, y).in_label:
                                    ref_pixels += 1
                                    ref_bitmap[y, x] = 255
                        contours_info = cv2.findContours(
                            ref_bitmap, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE
                        )
                        contours = (
                            contours_info[0]
                            if len(contours_info) == 2
                            else contours_info[1]
                        )
                        for contour in contours:
                            ref_perimeter += cv2.arcLength(contour, True)

                print(
                    "Detection "
                    f"{idx} pixels: detected={detected_pixels}, "
                    f"ref={ref_pixels}, "
                    f"detected_perimeter={detected_perimeter:.2f}, "
                    f"ref_perimeter={ref_perimeter:.2f}"
                )
                if show_plots:
                    summary = (
                        f"detected_pixels: {detected_pixels}\n"
                        f"ref_pixels: {ref_pixels}\n"
                        f"detected_perimeter: {detected_perimeter:.2f}\n"
                        f"ref_perimeter: {ref_perimeter:.2f}"
                    )
                    ax_text.text(
                        0.0,
                        1.0,
                        summary,
                        transform=ax_text.transAxes,
                        ha="left",
                        va="top",
                        fontsize=8,
                        wrap=True,
                    )

            if show_plots:
                ax.plot(xr, yr, color="black", zorder=3)
                if x_size is not None:
                    ax.axvline(0.0, color="black", linestyle=":")
                    ax.axvline(x_size, color="black", linestyle=":")

        if show_plots:
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
