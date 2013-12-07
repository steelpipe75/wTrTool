#include<stdio.h>
#include<stdlib.h>

typedef signed char		SINT8;
typedef signed short	SINT16;
typedef signed long		SINT32;
typedef unsigned char	UINT8;
typedef unsigned short	UINT16;
typedef unsigned long	UINT32;

#define ARRAY_MAX (10)

#define TEST_BIN_FILE_NAME	"array_test.dat"
#define TEST_TXT_FILE_NAME	"array_test.txt"

int main(int argc, char *argv[])
{
	FILE* bin_fp;
	FILE* txt_fp;
	
	struct {
		UINT8	a;
		SINT8	b;
		UINT16	c[2];
	} crr_dat;
	int i;
	
	
	printf("UINT8:%d\n",sizeof(UINT8));
	printf("UINT16:%d\n",sizeof(UINT16));
	printf("UINT32:%d\n",sizeof(UINT32));
	printf("SINT8:%d\n",sizeof(SINT8));
	printf("SINT16:%d\n",sizeof(SINT16));
	printf("SINT32:%d\n",sizeof(SINT32));
	
	bin_fp = fopen(TEST_BIN_FILE_NAME, "wb");
	if(bin_fp == NULL){
		fprintf(stderr, "%s can not open\n", TEST_BIN_FILE_NAME);
		exit(EXIT_FAILURE);
	}
	txt_fp = fopen(TEST_TXT_FILE_NAME, "w");
	if(txt_fp == NULL){
		fprintf(stderr, "%s can not open\n", TEST_TXT_FILE_NAME);
		exit(EXIT_FAILURE);
	}
	
	fprintf(txt_fp,"a,b,c[0],c[1]\n");
	for(i = 0; i < ARRAY_MAX; i++){
		crr_dat.a = i;
		crr_dat.b = i*(-2);
		crr_dat.c[0] = i*512;
		crr_dat.c[1] = i*2048;
		fprintf(txt_fp,"%d,%d,%d,%d\n",crr_dat.a,crr_dat.b,crr_dat.c[0],crr_dat.c[1]);
		fwrite(&crr_dat, sizeof(crr_dat), 1, bin_fp);
	}
	
	fclose(bin_fp);
	fclose(txt_fp);
	
	return 0;
}
