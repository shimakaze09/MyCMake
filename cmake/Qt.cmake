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

message(STATUS "Include Qt.cmake")

INCLUDE(Basic)

# must use macro
MACRO(QT_INIT)
    MESSAGE(STATUS "----------")
    CMAKE_PARSE_ARGUMENTS("ARG" "" "" "COMPONENTS" ${ARGN})
    LIST_PRINT(TITLE "QT COMPONENTS" PREFIX "  - " STRS ${ARG_COMPONENTS})
    FIND_PACKAGE(Qt5 COMPONENTS REQUIRED ${ARG_COMPONENTS})
    IF (WIN32)
        PATH_BACK(QT_ROOT ${Qt5_DIR} 3)
        FOREACH (CMPT ${ARG_COMPONENTS})
            set(DLL_PATH_RELEASE "${QT_ROOT}/bin/Qt5${CMPT}.dll")
            set(DLL_PATH_DEBUG "${QT_ROOT}/bin/Qt5${CMPT}d.dll")
            IF (EXISTS ${DLL_PATH_DEBUG} AND EXISTS ${DLL_PATH_RELEASE})
                INSTALL(FILES ${DLL_PATH_DEBUG} TYPE BIN CONFIGURATIONS Debug)
                INSTALL(FILES ${DLL_PATH_RELEASE} TYPE BIN CONFIGURATIONS Release)
            ELSE ()
                STATUS(WARNING "File not found: ${DLL_PATH_DEBUG} or ${DLL_PATH_RELEASE}")
            ENDIF ()
        ENDFOREACH ()
    ENDIF ()
ENDMACRO()

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