GLOBAL_GROUP_SOURCES(RST SOURCES PATHS
        ${CMAKE_CURRENT_SOURCE_DIR}
        "${PROJECT_SOURCE_DIR}/include/"
)

ADD_TARGET(MODE "EXE" SOURCES ${SOURCES})