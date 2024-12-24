# [ INTERFACE ]
#
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
# LIST_CHANGE_SEPARATOR(RST <RESULT-NAME> SEPARATOR <SEPARATOR> LIST <LIST>)
# - Separator '/': "a;b;c" -> "a/b/c"
#
# --------------------------------------------------
#
# GET_DIR_NAME(<RESULT-NAME>)
# - Get the name of the current directory
#
# --------------------------------------------------
#
# ADD_SUB_DIRS()
# - Add all subdirectories
#
# --------------------------------------------------
#
# GROUP_SOURCES(PATH <PATH> SOURCES <SOURCE-LIST>)
# - Create filters (recursive to <PATH>) for the source files
#
# --------------------------------------------------
#
# GLOBAL_GROUP_SOURCES(RST <RST> PATHS <PATH-LIST>)
# - Recursively glob all source files in <PATH-LIST> and call GROUP_SOURCES for each path
# - Regex: .+\.(h|hpp|inl|in|c|cc|cpp|cxx)
#
# --------------------------------------------------
#
# GET_TARGET_NAME(<RST> <TARGET_PATH>)
# - Get target name at <TARGET_PATH>
#
# --------------------------------------------------
#
# QT_BEGIN()
# - Call before the Qt target
#
# --------------------------------------------------
#
# QT_END()
# - Call after the Qt target
#
# --------------------------------------------------
#
# ADD_TARGET_GDR(MODE <mode> [QT <qt>] [SOURCES <sources-list>]
#     [LIBS_GENERAL <LIB-GENERAL-LIST>] [LIBS_DEBUG <LIB-DEBUG-LIST>] [LIBS_RELEASE <LIB-RELEASE-LIST>])
# - MODE            : EXE / LIB / DLL
# - LIB-GENERAL-LIST: auto add DEBUG_POSTFIX for debug mode
# - sources-list    : if sources is empty, call GLOBAL_GROUP_SOURCES for current path
# - auto set target name, folder, target prefix and some properties
#
# --------------------------------------------------
#
# ADD_TARGET(MODE <mode> [QT <qt>] [SOURCES <sources-list>] [LIBS <LIB-LIST>])
# - Call ADD_TARGET_GDR with LIBS_DEBUG and LIBS_RELEASE empty
#
# --------------------------------------------------

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
    LIST(LENGTH ARG_LIST LIST_LENGTH)
    IF ($<BOOL:${LIST_LENGTH}>)
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

FUNCTION(ADD_SUB_DIRS)
    FILE(GLOB CHILDREN RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*)
    SET(DIR_LIST "")
    FOREACH (CHILD ${CHILDREN})
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${CHILD})
            LIST(APPEND DIR_LIST ${CHILD})
        ENDIF ()
    ENDFOREACH ()
    FOREACH (DIR ${DIR_LIST})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "PATH" "SOURCES" ${ARGN})

    SET(HEADERS ${ARG_SOURCES})
    LIST(FILTER HEADERS INCLUDE REGEX ".+\.(h|hpp|inl|in)$")

    SET(SOURCES ${ARG_SOURCES})
    LIST(FILTER SOURCES INCLUDE REGEX ".+\.(c|cc|cpp|cxx)$")

    SET(QT_FILES ${ARG_SOURCES})
    LIST(FILTER QT_FILES INCLUDE REGEX ".+\.(qrc|ui)$")

    FOREACH (HEADER ${HEADERS})
        GET_FILENAME_COMPONENT(HEADER_PATH "${HEADER}" PATH)
        FILE(RELATIVE_PATH HEADER_PATH_REL ${ARG_PATH} "${HEADER_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" HEADER_PATH_REL_MSVC "${HEADER_PATH_REL}")
            SET(HEADER_PATH_REL "HEADERS\\${HEADER_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${HEADER_PATH_REL}" FILES "${HEADER}")
    ENDFOREACH ()

    FOREACH (SOURCE ${SOURCES})
        GET_FILENAME_COMPONENT(SOURCE_PATH "${SOURCE}" PATH)
        FILE(RELATIVE_PATH SOURCE_PATH_REL ${ARG_PATH} "${SOURCE_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" SOURCE_PATH_REL_MSVC "${SOURCE_PATH_REL}")
            SET(SOURCE_PATH_REL "SOURCES\\${SOURCE_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${SOURCE_PATH_REL}" FILES "${SOURCE}")
    ENDFOREACH ()

    FOREACH (QT_FILE ${QT_FILES})
        get_filename_component(QT_FILE_PATH "${QT_FILE}" PATH)
        FILE(RELATIVE_PATH QT_FILE_REL_PATH ${ARG_PATH} "${QT_FILE_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" QT_FILE_REL_PATH_MSVC "${QT_FILE_REL_PATH}")
            SET(QT_FILE_REL_PATH "QT\\${QT_FILE_REL_PATH_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${QT_FILE_REL_PATH}" FILES "${QT_FILE}")
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GLOBAL_GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "RST" "PATHS" ${ARGN})
    SET(SOURCES "")
    FOREACH (PATH ${ARG_PATHS})
        FILE(GLOB_RECURSE PATH_SOURCES
                "${PATH}/*.h"
                "${PATH}/*.hpp"
                "${PATH}/*.inl"
                "${PATH}/*.in"
                "${PATH}/*.c"
                "${PATH}/*.cc"
                "${PATH}/*.cpp"
                "${PATH}/*.cxx"
                "${path}/*.qrc"
                "${path}/*.ui"
        )
        LIST(APPEND SOURCES ${PATH_SOURCES})
        GROUP_SOURCES(PATH ${PATH} SOURCES ${PATH_SOURCES})
    ENDFOREACH ()
    SET(${ARG_RST} ${SOURCES} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(GET_TARGET_NAME RST TARGET_PATH)
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${TARGET_PATH}")
    STRING(REPLACE "/" "_" TARGET_NAME "${PROJECT_NAME}/${TARGET_REL_PATH}")
    SET(${RST} ${TARGET_NAME} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(QT_BEGIN)
    SET(CMAKE_AUTOMOC ON PARENT_SCOPE)
    SET(CMAKE_AUTOUIC ON PARENT_SCOPE)
    SET(CMAKE_AUTORCC ON PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(QT_END)
    SET(CMAKE_AUTOMOC OFF PARENT_SCOPE)
    SET(CMAKE_AUTOUIC OFF PARENT_SCOPE)
    SET(CMAKE_AUTORCC OFF PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ADD_TARGET_GDR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;QT" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
    SET(FOLDER_PATH "${PROJECT_NAME}/${TARGET_REL_PATH}")
    GET_TARGET_NAME(TARGET_NAME ${CMAKE_CURRENT_SOURCE_DIR})

    LIST(LENGTH ARG_SOURCES SOURCE_NUM)
    IF (${SOURCE_NUM} EQUAL 0)
        GLOBAL_GROUP_SOURCES(RST ARG_SOURCES PATHS ${CMAKE_CURRENT_SOURCE_DIR})
        LIST(LENGTH ARG_SOURCES SOURCE_NUM)
        IF (SOURCES_NUM EQUAL 0)
            MESSAGE(WARNING "Target ${TARGET_NAME} has no sources")
            RETURN()
        ENDIF ()
    ENDIF ()

    MESSAGE(STATUS "--------------------------------------------------")
    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER: ${FOLDER_PATH}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    LIST_PRINT(STRS ${ARG_SOURCES}
            TITLE "- SOURCES:"
            PREFIX "    ")

    LIST(LENGTH ARG_LIBS_GENERAL GENERAL_LIB_NUM)
    LIST(LENGTH ARG_LIBS_DEBUG DEBUG_LIB_NUM)
    LIST(LENGTH ARG_LIBS_RELEASE RELEASE_LIB_NUM)
    IF (${DEBUG_LIB_NUM} EQUAL 0 AND ${RELEASE_LIB_NUM} EQUAL 0)
        IF (NOT ${GENERAL_LIB_NUM} EQUAL 0)
            LIST_PRINT(STRS ${ARG_LIBS_GENERAL}
                    TITLE "- LIB:"
                    PREFIX "    ")
        ENDIF ()
    ELSE ()
        MESSAGE(STATUS "- LIBS:")
        LIST_PRINT(STRS ${ARG_LIBS_GENERAL}
                TITLE "  - GENERAL:"
                PREFIX "      ")
        LIST_PRINT(STRS ${ARG_LIBS_DEBUG}
                TITLE "  - DEBUG:"
                PREFIX "      ")
        LIST_PRINT(STRS ${ARG_LIBS_RELEASE}
                TITLE "  - RELEASE:"
                PREFIX "      ")
    ENDIF ()

    # Add target

    IF (${ARG_QT})
        QT_BEGIN()
    ENDIF ()

    IF (${ARG_MODE} STREQUAL "EXE")
        ADD_EXECUTABLE(${TARGET_NAME} ${ARG_SOURCES})
        IF (MSVC)
            SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")
        ENDIF ()
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
    ELSEIF (${ARG_MODE} STREQUAL "LIB")
        ADD_LIBRARY(${TARGET_NAME} ${ARG_SOURCES})
    ELSEIF (${ARG_MODE} STREQUAL "DLL")
        ADD_LIBRARY(${TARGET_NAME} SHARED ${ARG_SOURCES})
    ELSE ()
        MESSAGE(FATAL_ERROR "Unknown target mode: ${ARG_MODE}")
        RETURN()
    ENDIF ()

    # Folder
    SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES FOLDER ${FOLDER_PATH})

    FOREACH (LIB ${ARG_LIBS_GENERAL})
        TARGET_LINK_LIBRARIES(${TARGET_NAME} general ${LIB})
    ENDFOREACH ()
    FOREACH (LIB ${ARG_LIBS_DEBUG})
        TARGET_LINK_LIBRARIES(${TARGET_NAME} debug ${LIB})
    ENDFOREACH ()
    FOREACH (LIB ${ARG_LIBS_RELEASE})
        TARGET_LINK_LIBRARIES(${TARGET_NAME} optimized ${LIB})
    ENDFOREACH ()
    INSTALL(TARGETS ${TARGET_NAME}
            RUNTIME DESTINATION "bin"
            ARCHIVE DESTINATION "lib"
            LIBRARY DESTINATION "lib")
    IF (${ARG_QT})
        QT_END()
    ENDIF ()
ENDFUNCTION()

FUNCTION(ADD_TARGET)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;QT" "SOURCES;LIBS" ${ARGN})
    ADD_TARGET_GDR(MODE ${ARG_MODE} QT ${ARG_QT} SOURCES ${ARG_SOURCES} LIBS_GENERAL ${ARG_LIBS})
ENDFUNCTION()
