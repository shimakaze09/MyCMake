# ----------------------------------------------------------------------------
#
# LIST_PRINT(STRS <STRING_LIST> [TITLE <TITLE>] [PREFIX <PREFIX>])
# - print:
#          <TITLE>
#          <PREFIX>item0
#          ...
#          <PREFIX>itemN
#
# ----------------------------------------------------------------------------
#
# LIST_CHANGE_SEPARATOR(RST <RESULT_NAME> SEPARATOR <SEPARATOR> LIST <LIST>)
# - Separator '/': "a;b;c" -> "a/b/c"
#
# ----------------------------------------------------------------------------
#
# GET_DIR_NAME(<RESULT_NAME>)
# - Get current directory name.
#
# ----------------------------------------------------------------------------
#
# PATH_BACK(<RST> <PATH> <TIMES>)
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Basic.cmake")

FUNCTION(LIST_PRINT)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TITLE;PREFIX" "STRS" ${ARGN})
    IF (NOT ${ARG_TITLE} STREQUAL "")
        MESSAGE(STATUS ${ARG_TITLE})
    ENDIF ()
    FOREACH (STR ${ARG_STRS})
        MESSAGE(STATUS "${ARG_PREFIX}${STR}")
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(LIST_CHANGE_SEPARATOR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "RST;SEPARATOR" "LIST" ${ARGN})
    LIST(LENGTH ARG_LIST LIST_LEN)
    IF ($<BOOL:${LIST_LEN}>)
        SET(${ARG_RST} "" PARENT_SCOPE)
    ELSE ()
        SET(RST "")
        LIST(POP_BACK ARG_LIST BACK)
        FOREACH (ITEM ${ARG_LIST})
            SET(RST "${RST}${ITEM}${ARG_SEPARATOR}")
        ENDFOREACH ()
        SET(${ARG_RST} "${RST}${BACK}" PARENT_SCOPE)
    ENDIF ()
ENDFUNCTION()

FUNCTION(GET_DIR_NAME DIR_NAME)
    STRING(REGEX MATCH "([^/]*)$" TMP ${CMAKE_CURRENT_SOURCE_DIR})
    SET(${DIR_NAME} ${TMP} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(PATH_BACK RST PATH TIMES)
    MATH(EXPR STOP "${TIMES} - 1")
    SET(CURRENT_PATH ${PATH})
    FOREACH (INDEX RANGE ${STOP})
        STRING(REGEX MATCH "(.*)/" _ ${CURRENT_PATH})
        SET(CURRENT_PATH ${CMAKE_MATCH_1})
    ENDFOREACH ()
    SET(${RST} ${CURRENT_PATH} PARENT_SCOPE)
ENDFUNCTION()
