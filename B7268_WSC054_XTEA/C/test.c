#include <stdint.h>
#include <stdio.h>

#include "xtea.h"
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
	uint32_t enc_data[4] = { 0 };
	uint32_t dec_data[4] = { 0 };

	printf("Input Data  : 0x%x%x%x%x\n", data[0], data[1], data[2], data[3]);
	printf("Input Key   : 0x%x%x%x%x\n", key[0], key[1], key[2], key[3]);
	
	// 3rd parameter 0 = decode
	// 1 = encode
	xtea(key, data, 1, enc_data);
	// Perform the xtea algorithm, 
	printf("Data : 0x%x%x%x%x\n", enc_data[0], enc_data[1], enc_data[2], enc_data[3]);
	
	xtea(key, data, 0, dec_data);
	printf("Data : 0x%x%x%x%x\n", dec_data[0], dec_data[1], dec_data[2], dec_data[3]);
}