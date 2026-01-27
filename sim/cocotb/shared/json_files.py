from __future__ import annotations

import json
import os
from dataclasses import asdict
from pathlib import Path
from typing import Iterable, Any, Dict, List, Tuple

from shapes.Circle import Circle
from shapes.Ellipse import Ellipse
from shapes.Line import Line
from shapes.PixelShape import PixelShape

RESULTS_FILENAME = "results.json"


def find_results_json(root: os.PathLike[str] | str) -> Path | None:
    base = Path(root)
    path = base / "results" / RESULTS_FILENAME
    return path if path.exists() else None


def write_results(
    results_dir: os.PathLike[str] | str,
    results: Iterable[Any],
    shapes: Iterable[Any],
    *,
    x_size: int,
    height: int,
) -> Path:
    results_path = Path(results_dir) / RESULTS_FILENAME
    results_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {"x_size": x_size, "height": height},
        "shapes": [
            {"type": shape.kind, "params": shape.__dict__}
            for shape in shapes
        ],
        "detections": [asdict(r) for r in results],
    }
    with results_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    return results_path


def load_results(
    path: os.PathLike[str] | str,
) -> Tuple[List[Dict[str, Any]], List[Any], List[Dict[str, Any]], float | None, int | None]:
    with Path(path).open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    meta = payload.get("meta", {})
    x_size = float(meta["x_size"]) if "x_size" in meta else None
    height = int(meta["height"]) if "height" in meta else None
    detections = payload.get("detections", [])
    shape_items = payload.get("shapes", [])

    shapes = []
    shape_entries = []
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

    return detections, shapes, shape_entries, x_size, height
