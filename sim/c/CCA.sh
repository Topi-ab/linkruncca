#!/bin/sh

img="testimage/mandrill.pgm"


# image exist?
if [ ! -f $img ];
	then
	echo $img not found!
	exit
fi

# get image size and update header/parameters for simulation and verilog files
w=`identify -format '%w' $img`
h=`identify -format '%h' $img`
echo "char fname[]=\"$img\";" > sim.h
echo "unsigned int imwidth=$w;" >> sim.h
echo "unsigned int imheight=$h;" >> sim.h
echo "parameter imwidth=$w;" > ../src/cca.vh
echo "parameter imheight=$h;" >> ../src/cca.vh
#-----------------------------------------------

# verilator compilation
if [ -d "obj_dir" ];
	then
	rm -rf obj_dir
fi
verilator -Wall --cc "../src/LinkRunCCA.v" --exe sim_main.cpp -I"../src"
cd obj_dir
make -j -f VLinkRunCCA.mk "VLinkRunCCA"
cd ..
#-----------------------------------------------

# Simulation
echo 
echo "****************************Simulation Start****************************"
obj_dir/VLinkRunCCA
echo
echo "****************************Simulation Ended****************************"
#-----------------------------------------------

