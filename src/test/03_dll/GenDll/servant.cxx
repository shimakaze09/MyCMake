#include "test_03_dll/servant.hxx"

#include <iostream>

using namespace std;

void Servant::Speak() {
  cout << "dll: Servant::Speak" << endl;
}

DLL_SPEC void servant_speak() {
  Servant servant;
  cout << "servant_speak():" << endl << "\t";
  servant.Speak();
}