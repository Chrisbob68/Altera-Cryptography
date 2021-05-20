#include <stdint.h>
#include <stdio.h>

#include "xtea.h"
// This is for ease of building from commandline
// usually you dont include .c files
#include "xtea.c"


int main() {
	// input key
	uint32_t key[] = {
		0xDEADBEEF,
		0x01234567,
		0x89ABCDEF,
		0xDEADBEEF,
	};

	// intput data
	uint32_t data[] = {
		0xA5A5A5A5,
		0x01234567,
		0xFEDCBA98,
		0x5A5A5A5A,
	};

	// Buffer for output data
	uint32_t e_data_out[4] = { 0 };
	uint32_t d_data_out[4] = { 0 };

	printf("Input Data  : 0x%x%x%x%x\n", data[0], data[1], data[2], data[3]);
	printf("Input Key   : 0x%x%x%x%x\n", key[0], key[1], key[2], key[3]);
	
	// 3rd parameter 0 = decode
	// 1 = encode
	xtea(key, data, 1, e_data_out);
	printf("Data : 0x%x%x%x%x\n", e_data_out[0], e_data_out[1], e_data_out[2], e_data_out[3]);
	
	xtea(key, data, 0, d_data_out);
	printf("Data : 0x%x%x%x%x\n", d_data_out[0], d_data_out[1], d_data_out[2], d_data_out[3]);
}