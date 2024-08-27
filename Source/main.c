#include "trap.h"
#include "print.h"
#include "debug.h"

void KMain(void)
{
   char *string = "SysWare v0.0.1";
   
   init_idt();

   print("%s\n", string);
   ASSERT(0);
}