# ----------------------------------------------------------------------------
#
# QT_INSTALL()
# - Call before adding Qt target.
#
# ----------------------------------------------------------------------------
#
# QT_END()
# - Call after adding Qt target.
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include QT.cmake")

INCLUDE("${CMAKE_CURRENT_LIST_DIR}/Basic.cmake")

MACRO(QT_INIT)
    MESSAGE(STATUS "----------------------")
    CMAKE_PARSE_ARGUMENTS("ARG" "" "" "COMPONENTS" ${ARGN})
    LIST_PRINT(TITLE "QT Components" PREFIX "  - " STRS ${ARG_COMPONENTS})
    FIND_PACKAGE(Qt5 COMPONENTS REQUIRED ${ARG_COMPONENTS})
    SET(CMAKE_INCLUDE_CURRENT_DIR ON)
    IF (WIN32)
        PATH_BACK(QT_ROOT ${Qt5_DIR} 3)
        FOREACH (COMPONENT ${ARG_COMPONENTS})
            SET(DLL_PATH_RELEASE "${QT_ROOT}/bin/Qt5${COMPONENT}.dll")
            SET(DLL_PATH_DEBUG "${QT_ROOT}/bin/Qt5${COMPONENT}d.dll")
            IF (EXISTS ${DLL_PATH_DEBUG} AND EXISTS ${DLL_PATH_RELEASE})
                INSTALL(FILES ${DLL_PATH_DEBUG} TYPE BIN CONFIGURATIONS Debug)
                INSTALL(FILES ${DLL_PATH_RELEASE} TYPE BIN CONFIGURATIONS Release)
            ELSE ()
                MESSAGE(WARNING "Can't find Qt5${COMPONENT}(d).dll")
            ENDIF ()
        ENDFOREACH ()
    ENDIF ()
ENDMACRO()

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

