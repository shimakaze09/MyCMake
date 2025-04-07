IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    # using Clang
    IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10")
        MESSAGE(WARNING "clang (< 10) not support concept")
        RETURN()
    ENDIF ()
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10")
        MESSAGE(WARNING "gcc (< 10) not support concept")
        RETURN()
    ENDIF ()
    # using GCC
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    # using Visual Studio C++
    IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.23")
        MESSAGE(WARNING "MSVC (< 1923 / 2019 16.3) not support concept")
        RETURN()
    ENDIF ()
ENDIF ()

ADD_TARGET(
        TEST
        MODE EXE
)