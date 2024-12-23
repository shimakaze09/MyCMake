# [ INTERFACE ]
#
# GET_DIR_NAME(<RESULT-NAME>)
# - Get the name of the current directory
#
# ADD_SUB_DIRS()
# - Add all subdirectories
#
# ADD_CURRENT_PATH_SOURCES(<RESULT-NAME>)
# - Add all source files in the current directory: *.h, *.hpp, *.inl, *.cxx, *.cpp
#
# LIST_CHANGE_SEPARATOR(<RESULT-NAME> SEPARATOR <SEPARATOR> LIST <LIST>)
# - Separator '/': "a;b;c" -> "a/b/c"
#
# ADD_TARGET_GDR(MODE <MODE> NAME <NAME> SOURCES <SOURCES> 
#   LIBS_GENERAL <LIBS_GENERAL> LIBS_DEBUG <LIBS_DEBUG> LIBS_RELEASE <LIBS_RELEASE>)
# - MODE: EXE, LIB, DLL
# - Auto set the target properties: FOLDER, DEBUG_POSTFIX
#
# ADD_TARGET(MODE <MODE> NAME <NAME> SOURCES <SOURCES> LIBS <LIBS>)
# - Call ADD_TARGET_GDR with LIBS_DEBUG and LIBS_RELEASE empty
#
# QT_BEGIN()
# - Call before the Qt target
#
# QT_END()
# - Call after the Qt target

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
    GET_DIR_NAME(DIR_NAME)
    LIST(APPEND FOLDERS ${DIR_NAME})
    FOREACH (DIR ${DIR_LIST})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(ADD_CURRENT_PATH_SOURCES RST)
    FILE(GLOB SOURCES
            "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.inl"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.cxx"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.cc"
    )
    SET(${RST} ${SOURCES} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(LIST_CHANGE_SEPARATOR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "RST;SEPARATOR" "LIST" ${ARGN})
    MESSAGE(STATUS "- RESULT: ${ARG_RST}")
    MESSAGE(STATUS "- SEPARATOR: ${ARG_SEPARATOR}")
    MESSAGE(STATUS "- LIST:")
    FOREACH (ITEM ${ARG_LIST})
        MESSAGE(STATUS "    ${ITEM}")
    ENDFOREACH ()
    SET(RST "")
    LIST(LENGTH ARG_LIST LIST_LENGTH)
    IF ($<BOOL:${LIST_LENGTH}>)
        SET(${ARG_RST} "" PARENT_SCOPE)
    ELSE ()
        LIST(POP_BACK ARG_LIST BACK)
        FOREACH (ITEM ${ARG_LIST})
            SET(RST "${RST}${ITEM}${ARG_SEPARATOR}")
        ENDFOREACH ()
        SET(${ARG_RST} "${RST}${BACK}" PARENT_SCOPE)
    ENDIF ()
ENDFUNCTION()

FUNCTION(ADD_TARGET_GDR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;NAME" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
    LIST_CHANGE_SEPARATOR(RST FOLDER_PREFIX SEPARATOR "_" LIST ${FOLDERS})
    LIST_CHANGE_SEPARATOR(RST FOLDER_PATH SEPARATOR "/" LIST ${FOLDERS})
    SET(TARGET_NAME "${PROJECT_NAME}_${FOLDER_PREFIX}_${ARG_NAME}")

    MESSAGE(STATUS "--------------------------------------------------")

    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER: ${FOLDER_PATH}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    MESSAGE(STATUS "- SOURCES:")
    FOREACH (SOURCE ${ARG_SOURCES})
        MESSAGE(STATUS "    ${SOURCE}")
    ENDFOREACH ()
    MESSAGE(STATUS "- LIBS:")
    MESSAGE(STATUS "  - GENERAL:")
    FOREACH (LIB ${ARG_LIBS_GENERAL})
        MESSAGE(STATUS "      ${LIB}")
    ENDFOREACH ()
    MESSAGE(STATUS "  - DEBUG:")
    FOREACH (LIB ${ARG_LIBS_DEBUG})
        MESSAGE(STATUS "      ${LIB}")
    ENDFOREACH ()
    MESSAGE(STATUS "  - RELEASE:")
    FOREACH (LIB ${ARG_LIBS_RELEASE})
        MESSAGE(STATUS "      ${LIB}")
    ENDFOREACH ()

    IF (SOURCES_NUM EQUAL 0)
        MESSAGE(WARNING "Target ${TARGET_NAME} has no sources")
        RETURN()
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
            LIBRARY DESTINATION "lib"
    )

    MESSAGE(STATUS "--------------------------------------------------")
ENDFUNCTION()

FUNCTION(ADD_TARGET)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;NAME" "SOURCES;LIBS" ${ARGN})
    ADD_TARGET_GDR(MODE ${ARG_MODE} NAME ${ARG_NAME} SOURCES ${ARG_SOURCES} LIBS_GENERAL ${ARG_LIBS} LIBS_DEBUG "" LIBS_RELEASE "")
ENDFUNCTION()

FUNCTION(QT_BEGIN)
    SET(CMAKE_AUTOMOC ON PARENT_SCOPE)
    SET(CMAKE_AUTOMOC ON PARENT_SCOPE)
    SET(CMAKE_AUTOMOC ON PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(QT_END)
    SET(CMAKE_AUTOMOC OFF PARENT_SCOPE)
    SET(CMAKE_AUTOMOC OFF PARENT_SCOPE)
    SET(CMAKE_AUTOMOC OFF PARENT_SCOPE)
ENDFUNCTION()