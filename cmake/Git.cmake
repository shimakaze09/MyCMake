# ---------------------------------------------------------------------
#
# INIT_GIT()
# - Find git [REQUIRED]
#
# ---------------------------------------------------------------------
#
# UPDATE_SUBMODULES()
# - Update git submodules
#
# ---------------------------------------------------------------------

MESSAGE(STATUS "Include Git.cmake")

MACRO(INIT_GIT)
    MESSAGE(STATUS "--------------------------------------------------")
    FIND_PACKAGE(Git REQUIRED)
    MESSAGE(STATUS "Git found: ${GIT_EXECUTABLE}")
    MESSAGE(STATUS "Git executable: ${GIT_EXECUTABLE}")
    MESSAGE(STATUS "Git version: ${GIT_VERSION_STRING}")
ENDMACRO()

FUNCTION(UPDATE_SUBMODULES)
    IF (NOT GIT_FOUND)
        MESSAGE(FATAL_ERROR "You should call INIT_GIT() before UPDATE_SUBMODULES()")
    ENDIF ()
    EXECUTE_PROCESS(
            COMMAND ${GIT_EXECUTABLE} submodule init
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
    EXECUTE_PROCESS(
            COMMAND ${GIT_EXECUTABLE} submodule update
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
ENDFUNCTION()