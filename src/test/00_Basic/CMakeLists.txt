# Project name, default is the directory name
GET_DIR_NAME(DIRNAME)
SET(TARGET_NAME "${DIRNAME}")
# Use ';' to separate multiple directories
ADD_CURRENT_PATH_SRCS(SOURCES)

# Use ';' to separate multiple libraries
SET(LIBRARIES "")

ADD_TARGET(MODE "EXE" NAME "${PROJECT_NAME}_${TARGET_NAME}" SOURCES ${SOURCES} LIBS ${LIBRARIES})
