# Project name, default is the directory name
GET_DIR_NAME(DIRNAME)
SET(TARGET_NAME "${DIRNAME}")

# Use ';' to separate multiple directories
GLOBAL_GROUP_SOURCES(RST SOURCES PATHS ${CMAKE_CURRENT_SOURCE_DIR})

# Use ';' to separate multiple libraries
SET(LIBRARIES "${PROJECT_NAME}_test_02_lib_GenLib")

ADD_TARGET(MODE "EXE" NAME ${TARGET_NAME} SOURCES ${SOURCES} LIBS ${LIBRARIES})
