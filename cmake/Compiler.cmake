MESSAGE(STATUS "Include Compiler.cmake")

MACRO(SETUP_COMPILER)
    IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
        MESSAGE(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10")
            MESSAGE(FATAL_ERROR "Clang (< 10) does not support C++20 concepts")
        ENDIF ()
        
        # Only apply warning flags if we are the root project
        IF ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
            ADD_COMPILE_OPTIONS(-Wall -Wextra -Wpedantic)
        ENDIF()

    ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        MESSAGE(STATUS "Compiler: GCC ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10")
            MESSAGE(FATAL_ERROR "GCC (< 10) does not support C++20 concepts")
        ENDIF ()
        
        IF ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
            ADD_COMPILE_OPTIONS(-Wall -Wextra -Wpedantic)
        ENDIF()

    ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        MESSAGE(STATUS "Compiler: MSVC ${CMAKE_CXX_COMPILER_VERSION}")
        IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.26")
            MESSAGE(FATAL_ERROR "MSVC (< 19.26 / VS 2019 16.6) does not support C++20 concepts")
        ENDIF ()
        
        IF ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
            # /permissive- : Enforce standards conformance
            # /Zc:__cplusplus : Correctly report __cplusplus macro
            ADD_COMPILE_OPTIONS(/W4 /permissive- /Zc:__cplusplus)
        ENDIF()

    ELSE ()
        MESSAGE(WARNING "Unknown CMAKE_CXX_COMPILER_ID : ${CMAKE_CXX_COMPILER_ID}")
    ENDIF ()

    # Root project settings
    IF ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
        # Generate compile_commands.json (Compilation Database)
        SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)
        
        # Enable Interprocedural Optimization (LTO) for Release builds if supported
        INCLUDE(CheckIPOSupported)
        CHECK_IPO_SUPPORTED(RESULT IPO_SUPPORTED OUTPUT IPO_ERROR)
        IF(IPO_SUPPORTED)
            MESSAGE(STATUS "IPO / LTO supported. Enabling for Release builds.")
            SET(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
        ELSE()
            MESSAGE(STATUS "IPO / LTO not supported: ${IPO_ERROR}")
        ENDIF()
    ENDIF()
ENDMACRO()
