#include<stdio.h>
#include<stdlib.h>

typedef signed char		SINT8;
typedef signed short	SINT16;
typedef signed long		SINT32;
typedef unsigned char	UINT8;
typedef unsigned short	UINT16;
typedef unsigned long	UINT32;

#define ARRAY_MAX (10)

#define TEST_BIN_FILE_NAME	"union_test.dat"
#define TEST_TXT_FILE_NAME	"union_test.txt"

int main(int argc, char *argv[])
{
	FILE* bin_fp;
	FILE* txt_fp;
	
	UINT32	i;
	
	union {
		struct {
			UINT8	a;
			UINT8	b;
		} u8_2;
		struct {
			UINT16	c;
		} u16_1;
	} x;
	
	
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
	
	fprintf(txt_fp,"x.u8_2.a,x.u8_2.b,x.u16_1.c\n");
	for(i = 0; i < ARRAY_MAX; i++){
		x.u8_2.a = i;
		x.u8_2.b = 255 - i;
		fprintf(txt_fp,"%d,%d,%d\n",x.u8_2.a,x.u8_2.b,x.u16_1.c);
		fwrite(&x, sizeof(x), 1, bin_fp);
	}
	
	fclose(bin_fp);
	fclose(txt_fp);
	
	return 0;
}
