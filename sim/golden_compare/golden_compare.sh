#!/bin/bash

source ./files.sh

#echo $RTL_FILES

mkdir -p ghdl_work out

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl -i --std=08 --work=golden --workdir=ghdl_work $GOLDEN_FILES"

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl -i --std=08 --workdir=ghdl_work $RTL_FILES"

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl -i --std=08 --workdir=ghdl_work $TB_FILES"

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl -m --std=08 --workdir=ghdl_work -Pghdl_work $TB_TOP"

docker run --rm -u $(id -u):$(id -g) -v $GIT_ROOT:$GIT_ROOT -w $PWD anybytes/yosys bash -x -c "ghdl -r --std=08 --workdir=ghdl_work $TB_TOP"
