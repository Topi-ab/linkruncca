#include <verilated.h>          // Defines common routines
#include "VLinkRunCCA.h"        // From Verilator "Top.v"
#include <ctype.h>
#include <time.h>
#include "sim.h"
#include "ppm.h"

VLinkRunCCA *top;                      // Instantiation of module
unsigned int main_time = 0;     // Current simulation time

int x_bit=(int)ceil(log2(imwidth));
int y_bit=(int)ceil(log2(imheight));
int latency=4;

int main(int argc, char** argv) {
	clock_t time1,time2;
	time1=clock();
	Verilated::commandArgs(argc, argv);   // Remember args
	top = new VLinkRunCCA;             // Create instance

	FILE *finput,*foutput;
	int i,j,object=0,minx,maxx,miny,maxy;
	int m;int maskx=0,masky=0;
	for(m=0;m<y_bit;m=m+1) masky=(masky<<1)+1;
	for(m=0;m<x_bit;m=m+1) maskx=(maskx<<1)+1;

	unsigned long long int box;
	unsigned char *im;if(readPPM(fname,&im,&imwidth,&imheight))return 1; //read image

	//set original binary image to pixel 0 and 1
	for(i=0;i<imwidth;i++)
		for(j=0;j<imheight;j++)
			if(im[i+j*imwidth]!=0)
				im[i+j*imwidth]=1;

	//clear image border by setting them to 0
	i=0;          for(j=0;j<imheight;j++) im[i+j*imwidth]=0;
	i=imwidth-1;  for(j=0;j<imheight;j++) im[i+j*imwidth]=0;
	j=0;          for(i=0;i<imwidth;i++) im[i+j*imwidth]=0;
	j=imheight-1; for(i=0;i<imwidth;i++) im[i+j*imwidth]=0;

	//initialize input	
	unsigned int cycle=0;
	top->clk = 0;
	top->datavalid=0;
	top->rst=1;
	top->eval();            // Evaluate model
	top->rst = 0;  	 // Deassert reset

	while (!Verilated::gotFinish())
	{
		if(cycle==imwidth*imheight+latency-1)break; //simulation end when all pixel are send + latency

		top->datavalid=1;
		if(cycle<imwidth*imheight)top->pix_in=im[cycle];
		else top->pix_in=0;

		top->clk = 1;       // Toggle clock
		top->eval();            // Evaluate model
		top->clk = 0;
		top->eval();            // Evaluate model

		if(top->datavalid_out) //draw box and display output
		{
			object++;
			box=top->box_out;
			maxy=masky&(box);box=box>>y_bit;
			miny=masky&(box);box=box>>y_bit;
			maxx=maskx&(box);box=box>>x_bit;
			minx=maskx&(box);
			printf("minx: %-5umaxx: %-5uminy: %-5umaxy: %-5u ..produced at cycle %u\n",minx,maxx,miny,maxy,cycle);	//Display

			for(j=minx;j<=maxx;j++) //draw the box with pixel 2
			{	im[j+miny*imwidth]=2;im[j+maxy*imwidth]=2;		}
			for(j=miny;j<=maxy;j++)
			{	im[minx+j*imwidth]=2;im[maxx+j*imwidth]=2;		}
		}

		cycle++;
	}
	top->final();  // Done simulating
	
	printf("Total object: %d\nTotal Cycle: %u\n",object,cycle);

	for(i=0;i<imwidth*imheight;i++) im[i]=im[i]*127; //increase intensity for viewing
	writePPM("box_out.pgm",im,imwidth,imheight,0);

	time2=clock();
	printf("Simulation time: %lums\n",(time2-time1)/1000);
}

