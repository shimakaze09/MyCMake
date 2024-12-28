# [ Interface ]
#
# ----------------------------------------------------------------------------
#
# ADD_SUB_DIRS(<PATH>)
# - Add all subdirectories recursively in <PATH>
#
# ----------------------------------------------------------------------------
#
# GROUP_SOURCES(PATH <PATH> SOURCES <SOURCE-LIST>
# - Create filters (relative to <PATH>) for sources
#
# ----------------------------------------------------------------------------
#
# GLOBAL_GROUP_SOURCES(RST <RST> PATHS <PATH-LIST>)
# - Recursively glob all sources in <paths-list>
#   and call GROUP_SOURCES(PATH <PATH> SOURCES <SOURCE-LIST> for each path in <PATH-LIST>
# - regex : .+\.(h|hpp|inl|in|c|cc|cpp|cxx)
#
# ----------------------------------------------------------------------------
#
# GET_TARGET_NAME(<RST> <TARGET_PATH>)
# - Get target name at <TARGET_PATH>
#
# ----------------------------------------------------------------------------
#
# ADD_TARGET_GDR(MODE <MODE> [QT <QT>] [SOURCES <SOURCE-LIST>] [TEST <test>]
#     [LIBS_GENERAL <GENERAL-LIST>] [LIBS_DEBUG <DEBUG-LIST>] [LIBS_RELEASE <RELEASE-LIST>])
# - MODE         : EXE / LIB / DLL
# - QT           : default OFF, for moc, uic, qrc
# - TEST         : default OFF, test won't install
# - GENERAL-LIST : auto add DEBUG_POSTFIX for debug mode
# - SOURCE-LIST  : if sources is empty, call GLOBAL_GROUP_SOURCES for current path
# - Auto set target name, folder, target prefix and some properties
#
# ----------------------------------------------------------------------------
#
# ADD_TARGET(MODE <MODE> [QT <QT>] [TEST <TEST>] [SOURCES <SOURCE-LIST>] [LIBS <LIB-LIST>])
# - call ADD_TARGET_GDR(MODE <MODE> QT <QT> TEST <TEST> SOURCES <SOURCE-LIST> LIBS_GENERAL <LIB-LIST>)
#
# ----------------------------------------------------------------------------
#
# EXPORT_TARGETS()
# - export
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Build.cmake")

INCLUDE(Qt)

FUNCTION(ADD_SUB_DIRS PATH)
    MESSAGE(STATUS "----------")
    FILE(GLOB_RECURSE CHILDREN LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${PATH}/*)
    SET(DIRS "")
    FOREACH (ITEM ${CHILDREN})
        IF (IS_DIRECTORY ${ITEM} AND EXISTS "${ITEM}/CMakeLists.txt")
            LIST(APPEND DIRS ${ITEM})
        ENDIF ()
    ENDFOREACH ()
    LIST_PRINT(TITLE "DIRECTORIES:" PREFIX "- " STRS ${DIRS})
    FOREACH (DIR ${DIRS})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "PATH" "SOURCES" ${ARGN})

    SET(HEADERS ${ARG_SOURCES})
    list(FILTER HEADERS INCLUDE REGEX ".+\.(h|hpp|inl|in)$")

    SET(SOURCES ${ARG_SOURCES})
    list(FILTER SOURCES INCLUDE REGEX ".+\.(c|cc|cpp|cxx)$")

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
        GET_FILENAME_COMPONENT(QT_FILE_PATH "${QT_FILE}" PATH)
        FILE(RELATIVE_PATH QT_FILE_PATH_REL ${ARG_PATH} "${QT_FILE_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" QT_FILE_PATH_REL_MSVC "${QT_FILE_PATH_REL}")
            SET(QT_FILE_PATH_REL "Qt Files\\${QT_FILE_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${QT_FILE_PATH_REL}" FILES "${QT_FILE}")
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GLOBAL_GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "RST" "PATHS" ${ARGN})
    SET(SOURCES "")
    FOREACH (PATH ${ARG_PATHS})
        FILE(GLOB_RECURSE SOURCE_PATH
                "${PATH}/*.h"
                "${PATH}/*.hpp"
                "${PATH}/*.inl"
                "${PATH}/*.in"
                "${PATH}/*.c"
                "${PATH}/*.cc"
                "${PATH}/*.cpp"
                "${PATH}/*.cxx"
                "${PATH}/*.qrc"
                "${PATH}/*.ui"
        )
        LIST(APPEND SOURCES ${SOURCE_PATH})
        GROUP_SOURCES(PATH ${PATH} SOURCES ${SOURCE_PATH})
    ENDFOREACH ()
    SET(${ARG_RST} ${SOURCES} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(GET_TARGET_NAME RST TARGET_PATH)
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${TARGET_PATH}")
    STRING(REPLACE "/" "_" TARGET_NAME "${TARGET_REL_PATH}")
    SET(${RST} ${TARGET_NAME} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ADD_TARGET_GDR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;QT;TEST" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
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

    MESSAGE(STATUS "----------")
    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER: ${FOLDER_PATH}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    LIST_PRINT(STRS ${ARG_SOURCES}
            TITLE "- SOURCES:"
            PREFIX "    ")

    LIST(LENGTH ARG_LIBS_GENERAL GENERAL_LIBS)
    LIST(LENGTH ARG_LIBS_DEBUG DEBUG_LIBS)
    LIST(LENGTH ARG_LIBS_RELEASE RELEASE_LIBS)
    IF (${DEBUG_LIBS} EQUAL 0 AND ${RELEASE_LIBS} EQUAL 0)
        IF (NOT ${GENERAL_LIBS} EQUAL 0)
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
            SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
        ENDIF ()
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
        SET(TARGETS ${TARGET_NAME})
    ELSEIF (${ARG_MODE} STREQUAL "LIB")
        ADD_LIBRARY(${TARGET_NAME} ${ARG_SOURCES})
        ADD_LIBRARY("${PROJECT_NAME}::${TARGET_NAME}" ALIAS ${TARGET_NAME})
        SET(TARGETS ${TARGET_NAME})
    ELSEIF (${ARG_MODE} STREQUAL "DLL")
        ADD_LIBRARY(${TARGET_NAME} SHARED ${ARG_SOURCES})
        ADD_LIBRARY("${PROJECT_NAME}::${TARGET_NAME}" ALIAS ${TARGET_NAME})
        SET(TARGETS ${TARGET_NAME})
    ELSEIF (${ARG_MODE} STREQUAL "DS")
        ADD_LIBRARY("${TARGET_NAME}_shared" SHARED ${ARG_SOURCES})
        ADD_LIBRARY("${PROJECT_NAME}::${TARGET_NAME}_shared" ALIAS "${TARGET_NAME}_shared")
        ADD_LIBRARY("${TARGET_NAME}_static" STATIC ${ARG_SOURCES})
        ADD_LIBRARY("${PROJECT_NAME}::${TARGET_NAME}_static" ALIAS "${TARGET_NAME}_static")
        TARGET_COMPILE_DEFINITIONS("${TARGET_NAME}_static" PUBLIC -DMY_STATIC)
        SET(TARGETS "${TARGET_NAME}_shared;${TARGET_NAME}_static")
    ELSE ()
        MESSAGE(FATAL_ERROR "Unknown target mode: ${ARG_MODE}")
        RETURN()
    ENDIF ()

    FOREACH (TARGET ${TARGETS})
        SET_TARGET_PROPERTIES(${TARGET} PROPERTIES FOLDER ${FOLDER_PATH})

        FOREACH (LIB ${ARG_LIBS_GENERAL})
            TARGET_LINK_LIBRARIES(${TARGET} general ${LIB})
        ENDFOREACH ()
        FOREACH (LIB ${ARG_LIBS_DEBUG})
            TARGET_LINK_LIBRARIES(${TARGET} debug ${LIB})
        ENDFOREACH ()
        FOREACH (LIB ${ARG_LIBS_RELEASE})
            TARGET_LINK_LIBRARIES(${TARGET} optimized ${LIB})
        ENDFOREACH ()
        MESSAGE(STATUS "ARG_TEST: ${ARG_TEST}")
        IF (NOT "${ARG_TEST}" STREQUAL "ON")
            MESSAGE(STATUS "INSTALL")
            INSTALL(TARGETS ${TARGET}
                    EXPORT "${PROJECT_NAME}Targets"
                    RUNTIME DESTINATION "bin"
                    ARCHIVE DESTINATION "lib"
                    LIBRARY DESTINATION "lib")
        ENDIF ()
    ENDFOREACH ()

    IF (${ARG_QT})
        QT_END()
    ENDIF ()
ENDFUNCTION()

FUNCTION(ADD_TARGET)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;QT;TEST" "SOURCES;LIBS" ${ARGN})
    ADD_TARGET_GDR(MODE ${ARG_MODE} QT ${ARG_QT} TEST ${ARG_TEST} SOURCES ${ARG_SOURCES} LIBS_GENERAL ${ARG_LIBS})
ENDFUNCTION()

MACRO(EXPORT_TARGETS)
    # Install the configuration targets
    INSTALL(EXPORT "${PROJECT_NAME}Targets"
            FILE "${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )

    INCLUDE(CMakePackageConfigHelpers)

    # Generate the config file that is includes the exports
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "lib/${PROJECT_NAME}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # Generate the version file for the config file
    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION "${TUTOTIAL_VERSION_MAJOR}.${TUTOTIAL_VERSION_MINOR}"
            COMPATIBILITY AnyNewerVersion
    )

    # Install the configuration file
    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )

    # generate the export targets for the build tree
    # needs to be after the install(TARGETS ) command
    export(EXPORT "${PROJECT_NAME}Targets"
            FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
    )

    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )
ENDMACRO()