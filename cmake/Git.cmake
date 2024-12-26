# ----------------------------------------------------------------------------
#
# INIT_GIT()
# - Find git [required]
#
# ----------------------------------------------------------------------------
#
# UPDATE_SUBMODULE()
# - Update submodule
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Git.cmake")

MACRO(INIT_GIT)
    MESSAGE(STATUS "----------")
    FIND_PACKAGE(Git REQUIRED)
    MESSAGE(STATUS "GIT_FOUND: ${GIT_FOUND}")
    MESSAGE(STATUS "GIT_EXECUTABLE: ${GIT_EXECUTABLE}")
    MESSAGE(STATUS "GIT_VERSION_STRING: ${GIT_VERSION_STRING}")
ENDMACRO()

function(UPDATE_SUBMODULE)
    IF (NOT GIT_FOUND)
        MESSAGE(FATAL_ERROR "You should call INIT_GIT() first.")
    ENDIF ()
    EXECUTE_PROCESS(
            COMMAND ${GIT_EXECUTABLE} submodule init
            #OUTPUT_VARIABLE out
            #OUTPUT_STRIP_TRAILING_WHITESPACE
            #ERROR_QUIET
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
    EXECUTE_PROCESS(
            COMMAND ${GIT_EXECUTABLE} submodule update
            #OUTPUT_VARIABLE out
            #OUTPUT_STRIP_TRAILING_WHITESPACE
            #ERROR_QUIET
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
ENDFUNCTION()