#ifndef ppm_h
#define ppm_h

int writePPM(char* filename,unsigned char* im,unsigned long width,unsigned long height,int colour)
{
	int i,j;
	FILE *output;
	output=fopen(filename,"w");
	if(output==NULL){printf("File not found!");return 1;}
	if(colour)
	{
		fprintf(output,"P6\n%lu %lu\n255\n",width,height);
		for(i=0;i<height*width*3;i++)
			fputc(im[i],output);
	}
	else
	{
		fprintf(output,"P5\n%lu %lu\n255\n",width,height);
		for(i=0;i<height*width;i++)
			fputc(im[i],output);
	}
	fclose(output);
	return 0;
}

int readPPM(char* filename,unsigned char** im,unsigned int *width,unsigned int *height) //support P5 and P6 file type
{
	unsigned int i,j,maxPixValue,colour;
	FILE *input;
	char buffer;
	input=fopen(filename,"r");if(input==NULL){printf("Image not found!\n");return 1;}

	if(buffer=fgetc(input)!='P')
		{printf("Wrong image format!\n");return 1;}
	colour=fgetc(input)-'0'-5;

	while(!isdigit(buffer=fgetc(input)))
		if(buffer=='#') //skip comment
			while(fgetc(input)!='\n');
	*width=buffer-'0';
	while(isdigit(buffer=fgetc(input)))
		*width=*width*10+buffer-'0'; //width

	while(!isdigit(buffer=fgetc(input)))
		if(buffer=='#') //skip comment
			while(fgetc(input)!='\n');
	*height=buffer-'0';
	while(isdigit(buffer=fgetc(input)))
		*height=*height*10+buffer-'0'; //height

	while(!isdigit(buffer=fgetc(input)))
		if(buffer=='#') //skip comment
		{
			while(fgetc(input)!='\n');
		}
	maxPixValue=buffer-'0';
	while(isdigit(buffer=fgetc(input)))
		maxPixValue=maxPixValue*10+buffer-'0';
//	printf("%u\n",maxPixValue);

	//read image
	unsigned int w=*width;unsigned int h=*height;
	unsigned char* imread=(unsigned char*) malloc(w*h*3);if(imread==NULL){printf("malloc error\n");return 1;}

	if(colour)
		for(i=0;i<h*w*3;i++)imread[i]=fgetc(input);
	else
		for(i=0;i<h*w;i++)imread[i]=fgetc(input);

	fclose(input);
	*im=imread;
	return 0;
}

#endif
