# --------------------------------------------------
#
# LIST_PRINT(STRS <STRING-LIST> [TITLE <TITLE>] [PREFIX <PREFIX>])
# - Print:
#         <TITLE>
#         <PREFIX> item0
#         ...
#         <PREFIX> itemN
#
# --------------------------------------------------
#
# GET_DIR_NAME(<RESULT-NAME>)
# - Get the name of the current directory
#
# --------------------------------------------------
#
# PATH_BACK(<RST> <PATH> <TIMES>
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Basic.cmake")

FUNCTION(LIST_PRINT)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TITLE;PREFIX" "STRS" ${ARGN})
    LIST(LENGTH ARG_STRS STRS_LENGTH)
    IF (NOT STRS_LENGTH)
        RETURN()
    ENDIF ()
    IF (NOT ${ARG_TITLE} STREQUAL "")
        MESSAGE(STATUS ${ARG_TITLE})
    ENDIF ()
    FOREACH (STR ${ARG_STRS})
        MESSAGE(STATUS "${ARG_PREFIX}${STR}")
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GET_DIR_NAME DIR_NAME)
    STRING(REGEX MATCH "([^/]*)$" TMP ${CMAKE_CURRENT_SOURCE_DIR})
    SET(${DIR_NAME} ${TMP} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(PATH_BACK RST PATH TIMES)
    MATH(EXPR STOP "${TIMES}-1")
    SET(CURRENT_PATH ${PATH})
    FOREACH (INDEX RANGE ${STOP})
        STRING(REGEX MATCH "(.*)/" _ ${CURRENT_PATH})
        SET(CURRENT_PATH ${CMAKE_MATCH_1})
    ENDFOREACH ()
    SET(${RST} ${CURRENT_PATH} PARENT_SCOPE)
ENDFUNCTION()