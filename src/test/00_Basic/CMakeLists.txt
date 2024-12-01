# Project name, default is the directory name
GET_DIR_NAME(DIRNAME)
SET(TARGET_NAME "${TARGET_PREFIX}${DIRNAME}")
# Use ';' to separate multiple directories
FILE(GLOB SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/*.cxx"
        "${CMAKE_CURRENT_SOURCE_DIR}/*.hxx"
        "${CMAKE_CURRENT_SOURCE_DIR}/*.inl"
)

# Use ';' to separate multiple libraries
SET(LIBRARIES "")
ADD_TARGET(MODE ${MODE} NAME "${PROJECT_NAME}_${TARGET_NAME}" SOURCES ${SOURCES} LIBS ${LIBRARIES})
