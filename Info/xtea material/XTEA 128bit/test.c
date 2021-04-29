#include <stdint.h> 
#include <stdio.h>
#include "xtea.h"

int main(void)
{
  uint8_t  enc_dec;
  uint32_t key[4];
  uint32_t plan[4];
  uint32_t cipher[4];
  
  // Enc: 1, Dec: 0
  enc_dec = 1;
  
  key[0] = 0xDEADBEEF;
  key[1] = 0x01234567;
  key[2] = 0x89ABCDEF;  
  key[3] = 0xDEADBEEF; 


  if (enc_dec) {
    plan[0] = 0xA5A5A5A5;
    plan[1] = 0x01234567;  
    plan[2] = 0xFEDCBA98;
    plan[3] = 0x5A5A5A5A;
  }
  else {
    plan[0] = 0x089975E9;
    plan[1] = 0x2555F334;  
    plan[2] = 0xCE76E4F2;
    plan[3] = 0x4D932AB3;  	
  }

  xtea(key, plan, enc_dec, cipher);

  printf("%08x\n", cipher[0]); //Enc: 0x089975E9 - Dec: 0xA5A5A5A5
  printf("%08x\n", cipher[1]); //Enc: 0x2555F334 - Dec: 0x01234567
  printf("%08x\n", cipher[2]); //Enc: 0xCE76E4F2 - Dec: 0xFEDCBA98
  printf("%08x\n", cipher[3]); //Enc: 0x4D932AB3 - Dec: 0x5A5A5A5A
   
  return 0;
}