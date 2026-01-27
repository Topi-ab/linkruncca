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

DETECTIONS_FILENAME = "detections.json"
SHAPES_FILENAME = "shapes.json"


def find_first_json(root: os.PathLike[str] | str, filename: str) -> Path | None:
    matches = list(Path(root).rglob(filename))
    return matches[0] if matches else None


def write_detections(results_dir: os.PathLike[str] | str, results: Iterable[Any]) -> Path:
    results_path = Path(results_dir) / DETECTIONS_FILENAME
    results_path.parent.mkdir(parents=True, exist_ok=True)
    with results_path.open("w", encoding="utf-8") as handle:
        json.dump([asdict(r) for r in results], handle, indent=2)
    return results_path


def write_shapes(
    results_dir: os.PathLike[str] | str,
    shapes: Iterable[Any],
    *,
    x_size: int,
    height: int,
) -> Path:
    shapes_path = Path(results_dir) / SHAPES_FILENAME
    shapes_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {"x_size": x_size, "height": height},
        "shapes": [
            {"type": shape.kind, "params": shape.__dict__}
            for shape in shapes
        ],
    }
    with shapes_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    return shapes_path


def load_detections(path: os.PathLike[str] | str) -> List[Dict[str, Any]]:
    with Path(path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_shapes(
    path: os.PathLike[str] | str,
) -> Tuple[List[Any], List[Dict[str, Any]], float | None, int | None]:
    with Path(path).open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    shape_items = payload.get("shapes", [])
    meta = payload.get("meta", {})
    x_size = float(meta["x_size"]) if "x_size" in meta else None
    height = int(meta["height"]) if "height" in meta else None

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

    return shapes, shape_entries, x_size, height
