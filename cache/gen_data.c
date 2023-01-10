#include <stdio.h>

void main()
{
    int i;
    for(i=0; i<8192; i++)
        printf("%04x\n", i); 
}
