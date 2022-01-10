#include <stdint.h>
#include <stdio.h>
#include <string.h>

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
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
	};

	// Buffer for output data
	uint32_t e_data_out[4] = { 0 };
	uint32_t d_data_out[4] = { 0 };

	printf("Input Data  : 0x%x%x%x%x\n", data[0], data[1], data[2], data[3]);
	printf("Input Key   : 0x%x%x%x%x\n", key[0], key[1], key[2], key[3]);
	
    // Take User Input
    char inputstring [256];
    printf ("Insert your message to encrypt (Max 256 Characters): ");
    gets (inputstring);
    printf ("Your Initial Message is: %s\n",inputstring);
    int stringlength = strlen(inputstring);
    // Convert to ASCII Codes
    uint8_t AsciiRep[256];

    for (int x = 0; x < stringlength - 1; x++){
        // Turn the input string character into base 2, put the result in the AsciiRepresentation variable at position x
        itoa(inputstring[x],AsciiRep[x],2);
    }

    //Computes the number of iterations required to encode & decode the entire string.
    // 4 ascii characters fit inside 1 32 bit unsigned integer.
    int iterationsrequired = (stringlength + (32 / 2)) / 32) / 4; 

    uint8_t concatenated;

    for (int multiplier = 0; multiplier < iterationsrequired - 1;mutliplier++){
        for int offset = 0; y < 4; y++){
            concatenated += AsciiRep[(4*multiplier) + offset];
        }
        data[multiplier] = concatenated;
        concatenated = 0;
    }

    for (int x = 0; x < iterationsrequired / 4;x++){
		xtea(key, data, 1, e_data_out);
	}
	printf("Data : 0x%x%x%x%x\n", e_data_out[0], e_data_out[1], e_data_out[2], e_data_out[3]);
	uint32_t HPS_FPGA_bridge_write = (e_data_out, 1);

	uint32_t HPS_FPGA_bridge_read;
	
	d data_out = HPS_FPGA_bridge_read
	printf("Data : 0x%x%x%x%x\n", d_data_out[0], d_data_out[1], d_data_out[2], d_data_out[3]);
}