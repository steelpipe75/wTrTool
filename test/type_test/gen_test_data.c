#include<stdio.h>
#include<stdlib.h>

typedef signed char		SINT8;
typedef signed short	SINT16;
typedef signed long		SINT32;
typedef unsigned char	UINT8;
typedef unsigned short	UINT16;
typedef unsigned long	UINT32;

#define ARRAY_MAX (0xFFFFFFFF)

#define TEST_BIN_FILE_NAME	"array_test.dat"
#define TEST_TXT_FILE_NAME	"array_test.txt"

static void f(UINT32 i, FILE *txt_fp, FILE *bin_fp);
void g(UINT8 bit, UINT32 value, FILE *txt_fp);

int main(int argc, char *argv[])
{
	FILE* bin_fp;
	FILE* txt_fp;
	
	UINT32	i;
	
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
	
	fprintf(txt_fp,"UINT8,SINT8,BIT8,OCT8,HEX8,");
/*	fprintf(txt_fp,"DUMMY8,");	*/
	fprintf(txt_fp,"UINT16,SINT16,BIT16,OCT16,HEX16,");
/*	fprintf(txt_fp,"DUMMY16,");	*/
	fprintf(txt_fp,"UINT32,SINT32,BIT32,OCT32,HEX32");
/*	fprintf(txt_fp,",DUMMY32\n");	*/
	fprintf(txt_fp,"\n");
	
	for(i = 0x00000000; i <= 0x000000FF; i++){
		f(i, txt_fp, bin_fp);
	}
	
	for(i = 0x0000FF00; i <= 0x0000FFFF; i++){
		f(i, txt_fp, bin_fp);
	}
	
	for(i = 0xFF000000; i <= 0xFF0000FF; i++){
		f(i, txt_fp, bin_fp);
	}
	
	fclose(bin_fp);
	fclose(txt_fp);
	
	return 0;
}

void f(UINT32 i, FILE *txt_fp, FILE *bin_fp)
{
	UINT8	u8;
	UINT16	u16;
	UINT32	u32;
	
	struct {
		UINT8	v_UINT8;
		SINT8	v_SINT8;
		UINT8	v_BIT8;
		UINT8	v_OCT8;
		UINT8	v_HEX8;
		UINT8	v_DUMMY8;
		UINT16	v_UINT16;
		SINT16	v_SINT16;
		UINT16	v_BIT16;
		UINT16	v_OCT16;
		UINT16	v_HEX16;
		UINT16	v_DUMMY16;
		UINT16	padding;
		UINT32	v_UINT32;
		SINT32	v_SINT32;
		UINT32	v_BIT32;
		UINT32	v_OCT32;
		UINT32	v_HEX32;
		UINT32	v_DUMMY32;
	} crr_dat;
	
	u8	= i & 0x000000FF;
	u16	= i & 0x0000FFFF;
	u32	= i;
	
	crr_dat.v_UINT8		= u8;
	crr_dat.v_SINT8		= u8;
	crr_dat.v_BIT8		= u8;
	crr_dat.v_OCT8		= u8;
	crr_dat.v_HEX8		= u8;
	crr_dat.v_DUMMY8	= u8;
	crr_dat.v_UINT16	= u16;
	crr_dat.v_SINT16	= u16;
	crr_dat.v_BIT16		= u16;
	crr_dat.v_OCT16		= u16;
	crr_dat.v_HEX16		= u16;
	crr_dat.v_DUMMY16	= u16;
	crr_dat.padding		= u16;
	crr_dat.v_UINT32	= u32;
	crr_dat.v_SINT32	= u32;
	crr_dat.v_BIT32		= u32;
	crr_dat.v_OCT32		= u32;
	crr_dat.v_HEX32		= u32;
	crr_dat.v_DUMMY32	= u32;
	
	fprintf(txt_fp,"%d,%d,",	crr_dat.v_UINT8,crr_dat.v_SINT8);
	g(8, crr_dat.v_BIT8, txt_fp);
	fprintf(txt_fp,",0%03o,",	crr_dat.v_OCT8);
	fprintf(txt_fp,"0x%02X,",	crr_dat.v_HEX8 /* ,crr_dat.v_DUMMY8 */);
	fprintf(txt_fp,"%d,%d,",	crr_dat.v_UINT16,crr_dat.v_SINT16);
	g(16, crr_dat.v_BIT16, txt_fp);
	fprintf(txt_fp,",0%06o,",	crr_dat.v_OCT16);
	fprintf(txt_fp,"0x%04X,",	crr_dat.v_HEX16 /* ,crr_dat.v_DUMMY16 */);
	fprintf(txt_fp,"%d,%d,",	crr_dat.v_UINT32,crr_dat.v_SINT32);
	g(32, crr_dat.v_BIT32, txt_fp);
	fprintf(txt_fp,",0%011o,",	crr_dat.v_OCT32);
	fprintf(txt_fp,"0x%08X\n",	crr_dat.v_HEX32 /* ,crr_dat.v_DUMMY32 */);
	
	fwrite(&crr_dat, sizeof(crr_dat), 1, bin_fp);
	
	return;
}


void g(UINT8 bit, UINT32 value, FILE *txt_fp)
{
	UINT32 ptn;
	SINT8 cnt;
	UINT32 mask;
	
	fprintf(txt_fp,"0b");
	for(cnt = (bit-1); cnt >= 0; cnt--){
		mask = 1 << cnt;
		ptn = value & mask;
		if(ptn == 0){
			fprintf(txt_fp,"0");
		}else{
			fprintf(txt_fp,"1");
		}
	}
	
	return;
}
