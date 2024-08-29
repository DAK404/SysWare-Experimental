#include "trap.h"
#include "print.h"
#include "debug.h"
#include "memory.h"

void KMain(void)
{
   char *string = "==============\nSysWare v0.0.1\n==============\n";
   print("%s\n", string);
   
   init_idt();
   init_memory();
}