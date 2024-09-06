#include "include/trap.h"
#include "include/print.h"
#include "include/debug.h"
#include "include/memory.h"
#include "include/process.h"

void KMain(void)
{
   char *string = "==============\nSysWare v0.0.1\n==============\n";
   print("%s\n", string);
   
   init_idt();
   init_memory();  
   init_kvm();

   init_process();
   launch();
}