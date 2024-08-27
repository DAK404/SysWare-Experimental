#include "debug.h"
#include "print.h"

void error_check(char *file, uint64_t line)
{
    print("\n------------------------------------------\n");
    print("             ERROR CHECK");
    print("\n------------------------------------------\n");
    print("Assertion Failed [%s:%u]", file, line);

    while (1) { }
}