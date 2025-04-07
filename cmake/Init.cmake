# 1. include all cmake files
# 2. debug postfix
# 3. C++ 17
# 4. install prefix
# 5. set BUILD_TEST_${PROJECT_NAME}
# 6. output directory
# 7. use folder

MESSAGE(STATUS "Include Init.cmake")

INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Basic.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Build.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Download.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Git.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Package.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Qt.cmake")

#DOWNLOAD_FILE(
#        https://cdn.jsdelivr.net/gh/shimakaze09/MyData@main/MyCMake/CPM/CPM_3b40429.cmake
#        "${CMAKE_CURRENT_LIST_DIR}/CPM.cmake"
#        SHA256 438E319D455FD96E18F6CAD9DF596FCD5C9CA3590B1B2EDFA01AF7809CD7BEC7
#)
SET(CPM_USE_LOCAL_PACKAGES TRUE CACHE BOOL "" FORCE)
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")

# ---------------------------------------------------------

MACRO(INIT_PROJECT)
    SET(CMAKE_DEBUG_POSTFIX d)

    IF ("${ARG_CXX_STANDARD}" STREQUAL "")
        SET(ARG_CXX_STANDARD 20)
    ENDIF ()

    IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        # using Clang
        MESSAGE(STATUS "Compiler: Clang ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "11")
            MESSAGE(FATAL_ERROR "clang (< 11) not support concept")
            RETURN()
        ENDIF ()
    ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        MESSAGE(STATUS "Compiler: GCC ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10")
            MESSAGE(FATAL_ERROR "gcc (< 10) not support concept")
            RETURN()
        ENDIF ()
        # using GCC
    ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        # using Visual Studio C++
        MESSAGE(STATUS "Compiler: MSVC ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.26")
            MESSAGE(FATAL_ERROR "MSVC (< 1926 / 2019 16.6) not support concept")
            RETURN()
        ENDIF ()
    ENDIF ()

    MESSAGE(STATUS "CXX_STANDARD: ${ARG_CXX_STANDARD}")

    SET(CMAKE_CXX_STANDARD ${ARG_CXX_STANDARD})
    SET(CMAKE_CXX_STANDARD_REQUIRED True)

    IF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        PATH_BACK(ROOT ${CMAKE_INSTALL_PREFIX} 1)
        SET(CMAKE_INSTALL_PREFIX "${ROOT}/My" CACHE PATH "install prefix" FORCE)
    ENDIF ()

    SET("BUILD_TEST_${PROJECT_NAME}" TRUE CACHE BOOL "Build tests for ${PROJECT_NAME} ")

    IF (NOT ROOT_PROJECT_PATH)
        SET(ROOT_PROJECT_PATH ${PROJECT_SOURCE_DIR})
    ENDIF ()

    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${ROOT_PROJECT_PATH}/bin")
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${ROOT_PROJECT_PATH}/bin")
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${ROOT_PROJECT_PATH}/bin")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/lib")

    SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
ENDMACRO()