# Use "EXE" for executable, "LIB" for library
SET(MODE "EXE")

set(TARGET_PREFIX "Test_")

GET_DIR_NAME(DIRNAME)
SET(FOLDER_NAME "${DIRNAME}")

ADD_SUB_DIRS()