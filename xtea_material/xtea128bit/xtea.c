#include "xtea.h"

// XTEA: 128-bits
void xtea_enc(uint32_t **dest, const uint32_t **datav, const uint32_t **k) {
  uint8_t i;
  uint32_t y0 = *v[0], z0 = *v[1], y1 = *v[2], z1 = *v[3];
  uint32_t sum = 0, delta = 0x9E3779B9;

  for(i = 0; i < 32; i++) {
    y0  += ((z0 << 4 ^ z0 >> 5) + z0) ^ (sum + *k[sum & 3]);
    y1  += ((z1 << 4 ^ z1 >> 5) + z1) ^ (sum + *k[sum & 3]);
    sum += delta;
    z0  += ((y0 << 4 ^ y0 >> 5) + y0) ^ (sum + *k[sum>>11 & 3]);
	  z1  += ((y1 << 4 ^ y1 >> 5) + y1) ^ (sum + *k[sum>>11 & 3]);
  }
  *dest[0]=y0; *dest[1]=z0; *dest[2]=y1; *dest[3]=z1;
}

void xtea_dec(uint32_t **dest, const uint32_t **v, const uint32_t **k) {
  uint8_t i;
  uint32_t y0 = *v[0], z0 = *v[1], y1 = *v[2], z1 = *v[3];
  uint32_t sum = 0xC6EF3720, delta = 0x9E3779B9;
  for(i = 0; i < 32; i++) {
    z1  -= ((y1 << 4 ^ y1 >> 5) + y1) ^ (sum + *k[sum>>11 & 3]);
    z0  -= ((y0 << 4 ^ y0 >> 5) + y0) ^ (sum + *k[sum>>11 & 3]);
    sum -= delta;
    y1  -= ((z1 << 4 ^ z1 >> 5) + z1) ^ (sum + *k[sum & 3]);
    y0  -= ((z0 << 4 ^ z0 >> 5) + z0) ^ (sum + *k[sum & 3]);
  }
  *dest[0]=y0; *dest[1]=z0; *dest[2]=y1; *dest[3]=z1;
}

void xtea(uint32_t* key, uint32_t* input, uint8_t enc_dec, uint32_t *output){
  uint8_t i;
  uint32_t* d[4];
  const uint32_t* v[4];
  const uint32_t* k[4];

  for(i = 0; i < 4; i++) {
    d[i] = &output[3-i];
    v[i] = &input[3-i];
    k[i] = &key[3-i];
  }

  if (enc_dec)
    xtea_enc(d, v, k);
  else
    xtea_dec(d, v, k);
}

/* HERE IS THE PREVIOUS SOLUTION
//-----------------------------------------------------------------------------
// Original XTEA 64-bits
void xtea_enc(void *dest, const void *v, const void *k) {
  uint8_t i;
  uint32_t v0 = ((uint32_t*)v)[0], v1 = ((uint32_t*)v)[1];
  uint32_t sum = 0, delta = 0x9E3779B9;
  for(i = 0; i < 32; i++) {
    v0  += ((v1 << 4 ^ v1 >> 5) + v1) ^ (sum + ((uint32_t*)k)[sum & 3]);
    sum += delta;
    v1  += ((v0 << 4 ^ v0 >> 5) + v0) ^ (sum + ((uint32_t*)k)[sum>>11 & 3]);
  }
  ((uint32_t*)dest)[0]=v0; ((uint32_t*)dest)[1]=v1;
}

void xtea_dec(void *dest, const void *v, const void *k) {
  uint8_t i;
  uint32_t v0 = ((uint32_t*)v)[0], v1 = ((uint32_t*)v)[1];
  uint32_t sum = 0xC6EF3720, delta = 0x9E3779B9;
  for(i = 0; i < 32; i++) {
    v1  -= ((v0 << 4 ^ v0 >> 5) + v0) ^ (sum + ((uint32_t*)k)[sum>>11 & 3]);
    sum -= delta;
    v0  -= ((v1 << 4 ^ v1 >> 5) + v1) ^ (sum + ((uint32_t*)k)[sum & 3]);
  }
  ((uint32_t*)dest)[0]=v0; ((uint32_t*)dest)[1]=v1;
}
//-----------------------------------------------------------------------------
*/