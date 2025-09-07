#!/bin/bash

. ./golden_files.sh

mkdir -p synth_res

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl synth --std=08 $FILES -e $SYNTH_TOP >synth_res/synth.vho"
