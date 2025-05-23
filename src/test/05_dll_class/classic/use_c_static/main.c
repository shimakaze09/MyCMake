#include "../MyClass.h"

#include <stdio.h>
#include <stdlib.h>

int main() {
  size_t s = sizeof_MyClass();
  void* addr = malloc(s);
  MyClassHandle h = MyClass_Construct(addr);
  MyClass_SayHello(h);
  printf("(%d, %d)\n", h->x, h->y);
  MyClass_Destruct(h);
  free(addr);
  return 0;
}