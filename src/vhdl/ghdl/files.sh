#!/bin/bash

GIT_ROOT=$(git rev-parse --show-toplevel)
SRC="$GIT_ROOT/src/vhdl/"

FILES=""

FILES="$FILES $SIM_SRC/vhdl_linkruncca_pkg_ellipses.vhdl"

FILES="$FILES $SRC/vhdl_row_buf.vhdl"
FILES="$FILES $SRC/vhdl_table_ram_add.vhdl"
FILES="$FILES $SRC/vhdl_table_ram_data.vhdl"
FILES="$FILES $SRC/vhdl_table_reader.vhdl"
FILES="$FILES $SRC/vhdl_window.vhdl"
FILES="$FILES $SRC/vhdl_equivalence_resolver.vhdl"
FILES="$FILES $SRC/vhdl_feature_accumulator.vhdl"
FILES="$FILES $SRC/vhdl_holes_filler.vhdl"
FILES="$FILES $SRC/vhdl_linkruncca.vhdl"

SYNTH_TOP="vhdl_linkruncca"
