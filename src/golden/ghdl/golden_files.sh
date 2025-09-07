#!/bin/bash

GIT_ROOT=$(git rev-parse --show-toplevel)
SRC="$GIT_ROOT/src/golden/vhdl/"
SIM_SRC="$GIT_ROOT/sim/vhdl/"

FILES=""

FILES="$FILES $SRC/golden_linkruncca_pkg.vhdl"

FILES="$FILES $SRC/golden_row_buf.vhdl"
FILES="$FILES $SRC/golden_table_ram_add.vhdl"
FILES="$FILES $SRC/golden_table_ram_data.vhdl"
FILES="$FILES $SRC/golden_table_reader.vhdl"
FILES="$FILES $SRC/golden_window.vhdl"
FILES="$FILES $SRC/golden_equivalence_resolver.vhdl"
FILES="$FILES $SRC/golden_feature_accumulator.vhdl"
FILES="$FILES $SRC/golden_holes_filler.vhdl"
FILES="$FILES $SRC/golden_linkruncca.vhdl"

SYNTH_TOP="golden_linkruncca"
