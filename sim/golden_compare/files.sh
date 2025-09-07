#!/bin/bash

GIT_ROOT=$(git rev-parse --show-toplevel)

GOLDEN_SRC="$GIT_ROOT/src/golden/"
RTL_SRC="$GIT_ROOT/src/vhdl/"
TB_ROOT="$GIT_ROOT/src/golden/tb/"

source $GOLDEN_SRC/ghdl/golden_files.sh

GOLDEN_FILES=$FILES

source $RTL_SRC/ghdl/files.sh

RTL_FILES=$FILES

TB_FILES=$TB_ROOT/tb_golden_compare.vhdl

TB_TOP=tb_golden_compare
