#!/bin/sh

starttime=$(date +%s)

if test `ls -1 $1 | wc -l` -ne 1
then	printf "shtask: Input .v file error.\nusage:sh v2c <inputfile.v>\n" 
	exit
fi

fname="${1%%.*}"
echo "input file:$fname"

verilator -Wall --cc "$1" --exe sim_main.cpp
cd obj_dir
make -j -f V$fname.mk "V$fname"
echo run with: obj_dir/V$fname

endtime=$(date +%s)

echo "Compile time : $(($endtime-$starttime))s"


