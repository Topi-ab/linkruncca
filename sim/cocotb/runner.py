#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, List

from cocotb_tools.runner import get_runner

import importlib.util


def _load_post_analysis():
    module_path = Path(__file__).resolve().parent / "runner" / "post_analysis.py"
    spec = importlib.util.spec_from_file_location("runner_post_analysis", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Failed to load post-analysis module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.run_post_analysis


_run_post_analysis = _load_post_analysis()


SIMULATOR = "nvc"
TOPLEVEL = "vhdl_linkruncca"
TEST_MODULE = "test_linkruncca"
VHDL_PKG = "vhdl_linkruncca_pkg_ellipses_linescan.vhdl"
VHDL_STD = "08"
INCLUDE_TB = False


def _default_sources(root: Path, hdl_toplevel: str) -> List[Path]:
    src_vhdl = root / "src" / "vhdl"
    sim_vhdl = root / "sim" / "vhdl"

    sources = [
        src_vhdl / "vhdl_linkruncca_util_pkg.vhdl",
        sim_vhdl / VHDL_PKG,
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

    if INCLUDE_TB or hdl_toplevel == "tb_linkruncca":
        sources.append(sim_vhdl / "tb_linkruncca.vhdl")

    return sources


def _default_parameters() -> Dict[str, int]:
    params: Dict[str, int] = {}
    return params


def run() -> None:
    root = Path(__file__).resolve().parents[2]
    sim = SIMULATOR
    hdl_toplevel = TOPLEVEL
    test_module = TEST_MODULE

    std_arg = f"--std={VHDL_STD}"
    build_args: List[str] = [std_arg, "--ieee-warnings=off"]
    test_args: List[str] = []

    sources = _default_sources(root, hdl_toplevel)
    build_dir = Path(root / "sim" / "cocotb" / "sim_build")

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
    _run_post_analysis(build_dir)


if __name__ == "__main__":
    run()
