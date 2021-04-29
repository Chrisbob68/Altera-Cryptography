#ifndef _XTEA_H_
#define _XTEA_H_

#include <stdint.h>

void xtea(uint32_t* key, uint32_t* input, uint8_t enc_dec, uint32_t *output);

#endif //_XTEA_H_
