ADD_TARGET(
  TEST
  RET_TARGET_NAME tname
  MODE EXE
)

ADD_DEPENDENCIES(${tname} MyCMake_test_04_dll_gen)