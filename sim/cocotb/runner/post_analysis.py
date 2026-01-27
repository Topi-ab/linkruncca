from __future__ import annotations

import math
import os
import signal
import warnings
from pathlib import Path

from shapes.ShapeDb import ShapeDb
from shared.json_files import RESULTS_FILENAME, find_results_json, load_results

_NONINTERACTIVE_BACKENDS = {
    "agg",
    "cairo",
    "pdf",
    "pgf",
    "ps",
    "svg",
    "template",
}

_PLOT_COLORS = [
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


def _env_bool(name: str, default: bool = True) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _load_plotting(show_plots: bool):
    if not show_plots:
        return False, None, None

    try:
        import matplotlib.pyplot as plt
        from matplotlib.patches import Rectangle
    except Exception as exc:
        raise RuntimeError("matplotlib is required for plotting detections") from exc

    backend = (plt.get_backend() or "").lower()
    if backend in _NONINTERACTIVE_BACKENDS:
        warnings.warn(
            (
                f"Matplotlib backend '{plt.get_backend()}' is non-interactive; "
                "disabling plots. Set DISABLE_PLOT=1 to silence this warning "
                "or configure an interactive backend/X11."
            ),
            UserWarning,
        )
        return False, None, None

    return True, plt, Rectangle


def _ellipse_points(cx: float, cy: float, major: float, minor: float, theta: float):
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

    return xr, yr, x_plot_min, x_plot_max, y_plot_min, y_plot_max


def _setup_axes(plt, idx: int, x_plot_min: int, x_plot_max: int, y_plot_min: int, y_plot_max: int):
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
    return ax, ax_text


def _compute_overlaps(shapes, shape_entries, item):
    overlapping_shapes = []
    overlap_kinds = []
    overlap_flags = []
    for shape, entry in zip(shapes, shape_entries):
        hit = shape.intersects_ellipse(item)
        overlap_flags.append(hit)
        if hit:
            overlapping_shapes.append(shape)
            overlap_kinds.append(shape)
    return overlapping_shapes, overlap_kinds, overlap_flags


def _shape_bounds(entry):
    params = entry.get("params", {})
    shape_type = entry.get("type")
    if shape_type == "circle":
        cx_s = float(params.get("cx", 0.0))
        cy_s = float(params.get("cy", 0.0))
        r = float(params.get("r", 0.0))
        return cx_s - r, cx_s + r, cy_s - r, cy_s + r
    if shape_type == "ellipse":
        cx_s = float(params.get("cx", 0.0))
        cy_s = float(params.get("cy", 0.0))
        rx = float(params.get("rx", 0.0))
        ry = float(params.get("ry", 0.0))
        return cx_s - rx, cx_s + rx, cy_s - ry, cy_s + ry
    if shape_type == "line":
        x0 = float(params.get("x0", 0.0))
        y0 = float(params.get("y0", 0.0))
        x1 = float(params.get("x1", 0.0))
        y1 = float(params.get("y1", 0.0))
        width = float(params.get("width", 0.0))
        half = width / 2.0
        return min(x0, x1) - half, max(x0, x1) + half, min(y0, y1) - half, max(y0, y1) + half
    if shape_type == "pixel":
        px = float(params.get("x", 0.0))
        py = float(params.get("y", 0.0))
        return px - 0.5, px + 0.5, py - 0.5, py + 0.5
    return None


def _expand_plot_bounds(
    x_plot_min: int,
    x_plot_max: int,
    y_plot_min: int,
    y_plot_max: int,
    shape_entries,
    overlap_flags,
    x_size: float | None,
):
    x_min = x_plot_min
    x_max = x_plot_max
    y_min = y_plot_min
    y_max = y_plot_max

    for entry, hit in zip(shape_entries, overlap_flags):
        if not hit:
            continue
        bounds = _shape_bounds(entry)
        if bounds is None:
            continue
        sx0, sx1, sy0, sy1 = bounds
        if x_size is not None:
            if sx1 < 0.0 or sx0 > x_size:
                continue
            sx0 = max(sx0, 0.0)
            sx1 = min(sx1, x_size)
        x_min = min(x_min, math.floor(sx0) - 2)
        x_max = max(x_max, math.ceil(sx1) + 2)
        y_min = min(y_min, math.floor(sy0) - 2)
        y_max = max(y_max, math.ceil(sy1) + 2)

    return x_min, x_max, y_min, y_max


def _plot_shapes(ax, Rectangle, shape_entries, overlap_flags):
    plot_idx = 0
    for entry, hit in zip(shape_entries, overlap_flags):
        if not hit:
            continue
        color = _PLOT_COLORS[plot_idx % len(_PLOT_COLORS)]
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
            ax.fill(xs, ys, color=color, alpha=0.35, zorder=1)
        elif shape_type == "ellipse":
            cx_s = params.get("cx", 0.0)
            cy_s = params.get("cy", 0.0)
            rx = params.get("rx", 0.0)
            ry = params.get("ry", 0.0)
            angles = [i * 2.0 * math.pi / 360.0 for i in range(361)]
            xs = [cx_s + rx * math.cos(t) for t in angles]
            ys = [cy_s + ry * math.sin(t) for t in angles]
            ax.fill(xs, ys, color=color, alpha=0.35, zorder=1)
        elif shape_type == "line":
            x0 = params.get("x0", 0.0)
            y0 = params.get("y0", 0.0)
            x1 = params.get("x1", 0.0)
            y1 = params.get("y1", 0.0)
            ax.plot([x0, x1], [y0, y1], color=color, linewidth=2, zorder=1)
        elif shape_type == "pixel":
            px = params.get("x", 0.0)
            py = params.get("y", 0.0)
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


def _compute_reference_metrics(overlapping_shapes, x_size, height, np, cv2):
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
            contours = contours_info[0] if len(contours_info) == 2 else contours_info[1]
            for contour in contours:
                ref_perimeter += cv2.arcLength(contour, True)
    return ref_pixels, ref_perimeter


def _plot_detection_summary(ax_text, detected_pixels, ref_pixels, detected_perimeter, ref_perimeter):
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


def _finalize_plots(plt):
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


def run_post_analysis(build_dir: Path) -> None:
    results_path = find_results_json(build_dir)
    if results_path is None:
        return

    show_plots = not _env_bool("DISABLE_PLOT", False)
    try:
        import numpy as np
    except Exception as exc:
        raise RuntimeError("numpy is required for pixel map generation") from exc
    try:
        import cv2
    except Exception as exc:
        raise RuntimeError("opencv-python is required for perimeter calculation") from exc

    show_plots, plt, Rectangle = _load_plotting(show_plots)

    items, shapes, shape_entries, x_size, height = load_results(results_path)

    if shapes and (x_size is None or height is None):
        raise RuntimeError(
            "results.json meta x_size and height are required for ref pixel map generation"
        )

    for idx, item in enumerate(items):
        cx = float(item.get("cx", 0.0))
        cy = float(item.get("cy", 0.0))
        major = float(item.get("major", 0.0))
        minor = float(item.get("minor", 0.0))
        theta = float(item.get("theta", 0.0))

        xr, yr, x_plot_min, x_plot_max, y_plot_min, y_plot_max = _ellipse_points(
            cx, cy, major, minor, theta
        )

        if show_plots:
            ax, ax_text = _setup_axes(
                plt, idx, x_plot_min, x_plot_max, y_plot_min, y_plot_max
            )

        if shapes:
            overlapping_shapes, overlap_kinds, overlap_flags = _compute_overlaps(
                shapes, shape_entries, item
            )
            if overlap_kinds:
                print(
                    "Detection "
                    f"{idx} overlaps shapes: {', '.join(s.kind for s in overlap_kinds)}"
                )
            else:
                print(f"Detection {idx} overlaps shapes: none")

            if show_plots and x_size is not None and overlap_flags:
                x_plot_min, x_plot_max, y_plot_min, y_plot_max = _expand_plot_bounds(
                    x_plot_min,
                    x_plot_max,
                    y_plot_min,
                    y_plot_max,
                    shape_entries,
                    overlap_flags,
                    x_size,
                )
                ax.set_xlim(x_plot_min, x_plot_max)
                ax.set_ylim(y_plot_max, y_plot_min)

            if show_plots:
                _plot_shapes(ax, Rectangle, shape_entries, overlap_flags)

            detected_pixels = int(item.get("pixels", 0))
            detected_perimeter = float(item.get("perimeter", 0.0))
            ref_pixels, ref_perimeter = _compute_reference_metrics(
                overlapping_shapes, x_size, height, np, cv2
            )

            print(
                "Detection "
                f"{idx} pixels: detected={detected_pixels}, "
                f"ref={ref_pixels}, "
                f"detected_perimeter={detected_perimeter:.2f}, "
                f"ref_perimeter={ref_perimeter:.2f}"
            )
            if show_plots:
                _plot_detection_summary(
                    ax_text,
                    detected_pixels,
                    ref_pixels,
                    detected_perimeter,
                    ref_perimeter,
                )

        if show_plots:
            ax.plot(xr, yr, color="black", zorder=3)
            if x_size is not None:
                ax.axvline(0.0, color="black", linestyle=":")
                ax.axvline(x_size, color="black", linestyle=":")

    if show_plots:
        _finalize_plots(plt)
