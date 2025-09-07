#!/bin/sh

. ./files.sh

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl synth --std=08 $FILES -e $SYNTH_TOP >synth.vho"