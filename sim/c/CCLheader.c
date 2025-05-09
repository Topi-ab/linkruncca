#include <stdio.h>
#include <math.h>

int main(int argc,char** argv)
{
	if(argc!=2){printf("usage: CCLheader <image.ppm>\n"); return 1; }

int latency=4; //latency to offset counter x, 4 if holes filling, else 3
unsigned int imwidth;
unsigned int imheight;

	char fname[50];//="testimage/mandrill.ppm";
	sprintf(fname,"testimage/%s",argv[1]);
	printf("Input image: %s\n",fname);

//////////////////////get image size from header///////////////////////////////
	unsigned int i,j,maxPixValue,colour;
	FILE *input;
	char buffer;
	input=fopen(fname,"r");if(input==NULL){printf("Image not found!\n");return 1;}

	if(buffer=fgetc(input)!='P')
		{printf("Wrong image format!\n");return 1;}
	colour=fgetc(input)-'0'-5;

	while(!isdigit(buffer=fgetc(input)))
		if(buffer=='#') //skip comment
			while(fgetc(input)!='\n');
	imwidth=buffer-'0';
	while(isdigit(buffer=fgetc(input)))
		imwidth=imwidth*10+buffer-'0'; //imwidth

	while(!isdigit(buffer=fgetc(input)))
		if(buffer=='#') //skip comment
			while(fgetc(input)!='\n');
	imheight=buffer-'0';
	while(isdigit(buffer=fgetc(input)))
		imheight=imheight*10+buffer-'0'; //imheight
	fclose(input);
//////////////////////get image size from header (END)//////////////////////////

int x_bit=(int)ceil(log2(imwidth));
int y_bit=(int)ceil(log2(imheight));
int address_bit=(int)ceil(log2(imwidth/2));
int data_bit=2*(x_bit+y_bit);

	FILE *foutput;
	if((foutput=fopen("CCL.vh","w"))==NULL){printf("File not open.\n");return 1;}
	fprintf(foutput,"`ifndef CCL_vh\n`define CCL_vh\n");
	fprintf(foutput,"\tparameter imwidth=%d;\n",imwidth);
	fprintf(foutput,"\tparameter imheight=%d;\n",imheight);
	fprintf(foutput,"\tparameter x_bit=%d;\n",x_bit);
	fprintf(foutput,"\tparameter y_bit=%d;\n",y_bit);
	fprintf(foutput,"\tparameter address_bit=%d;\n",address_bit);
	fprintf(foutput,"\tparameter data_bit=%d;\n",data_bit);
	fprintf(foutput,"\tparameter latency=%d;\n",latency);
	fprintf(foutput,"`endif");
	fclose(foutput);

	if((foutput=fopen("CCL.h","w"))==NULL){printf("File not open.\n");return 1;}
	fprintf(foutput,"#ifndef CCL_h\n#define CCL_h\n");
	fprintf(foutput,"\tchar fname[50]=\"%s\";\n",fname);
	fprintf(foutput,"\tunsigned int imwidth=%d;\n",imwidth);
	fprintf(foutput,"\tunsigned int imheight=%d;\n",imheight);
	fprintf(foutput,"\tint x_bit=%d;\n",x_bit);
	fprintf(foutput,"\tint y_bit=%d;\n",y_bit);
	fprintf(foutput,"\tint address_bit=%d;\n",address_bit);
	fprintf(foutput,"\tint data_bit=%d;\n",data_bit);
	fprintf(foutput,"\tint latency=%d;\n",latency);
	fprintf(foutput,"#endif");
	fclose(foutput);

	return 0;
}

