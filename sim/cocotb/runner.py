#!/usr/bin/env python3
from __future__ import annotations

import os
import shlex
from pathlib import Path
from typing import Dict, List

from cocotb_tools.runner import get_runner


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


if __name__ == "__main__":
    run()
