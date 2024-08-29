#include "include/trap.h"
#include "include/print.h"
#include "include/debug.h"
#include "include/memory.h"

void KMain(void)
{
   char *string = "==============\nSysWare v0.0.1\n==============\n";
   print("%s\n", string);
   
   init_idt();
   init_memory();
}