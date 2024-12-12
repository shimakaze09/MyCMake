# [ Interface ]
#
# ----------------------------------------------------------------------------
#
# ADD_SUB_DIRS_REC(<PATH>)
# - Add all subdirectories recursively in <PATH>.
#
# ----------------------------------------------------------------------------
#
# GROUP_SOURCES(PATH <PATH> SOURCES <SOURCES_LIST>)
# - Create filters (relive to <PATH>) for source files.
#
# ----------------------------------------------------------------------------
#
# GLOBAL_GROUP_SOURCES(RST <RST> PATHS <PATH_LIST>)
# - Recursively glob all source files in <PATH_LIST>.
# - Regex: .+.\.(c|cpp|cxx|h|hpp|hxx|inl|ipp|tpp|txx|ixx|m|mm|in)
#
# ----------------------------------------------------------------------------
#
# GET_TARGET_NAME(<RST> <TARGET_PATH>)
# - Get target name at <TARGET_PATH>.
#
# ----------------------------------------------------------------------------
#
# ADD_TARGET_GDR(MODE <MODE>
#                [QT <QT>]
#                [TEST <TEST>]
#                [SOURCE <SOURCE_LIST>]
#                [LIBS_GENERAL <LIBS_GENERAL_LIST>]
#                [LIBS_DEBUG <LIBS_DEBUG_LIST>]
#                [LIBS_RELEASE <LIBS_RELEASE_LIST>])
# - MODE: EXE, LIB, DLL
# - QT: Default is OFF, for moc, uic, qrc.
# - TEST: Default is OFF, for test target.
# - SOURCE: Source files.
# - LIBS_DEBUG: auto add debug postfix.
# - SOURCE_LIST: If empty, auto glob all source files in current directory.
# - Auto set target name, folder, and some properties.
#
# ----------------------------------------------------------------------------
#
# ADD_TARGET(MODE <MODE> [SOURCE <SOURCE_LIST>] [LIBS <LIBS_LIST>])
# - Call ADD_TARGET(MODE <MODE> SOURCE <SOURCE_LIST> LIBS_GENERAL <LIBS_LIST>)
#
# ----------------------------------------------------------------------------
#
#
# EXPORT_TARGETS([INC <INC>])
# - Export some files
# - INC: default is ON, install include/
#
# ----------------------------------------------------------------------------
#
# INIT_INSTALL_PREFIX()
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Build.cmake")

INCLUDE("${CMAKE_CURRENT_LIST_DIR}/QT.cmake")

MACRO(INIT_INSTALL_PREFIX)
    IF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        PATH_BACK(ROOT ${CMAKE_INSTALL_PREFIX} 1)
        SET(CMAKE_INSTALL_PREFIX "${ROOT}/My" CACHE PATH "INSTALL PREFIX" FORCE)
    ENDIF ()
ENDMACRO()

FUNCTION(ADD_SUB_DIRS_REC PATH)
    MESSAGE(STATUS "--------------------------------------------------")
    FILE(GLOB_RECURSE CHILDREN LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${PATH}/*)
    SET(DIRS "")
    FOREACH (ITEM ${CHILDREN})
        IF (IS_DIRECTORY ${ITEM} AND EXISTS "${ITEM}/CMakeLists.txt")
            LIST(APPEND DIRS ${ITEM})
        ENDIF ()
    ENDFOREACH ()
    LIST_PRINT(TITLE "SUB DIRS" PREFIX "  - " STRS ${DIRS})
    FOREACH (DIR ${DIRS})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "PATH" "SOURCES" ${ARGN})

    SET(HEADERS ${ARG_SOURCES})
    LIST(FILTER HEADERS INCLUDE REGEX ".+\.(h|hpp|hxx|inl|ipp|tpp|txx|ixx)$")

    SET(SOURCES ${ARG_SOURCES})
    LIST(FILTER SOURCES INCLUDE REGEX ".+\.(c|cc|cpp|cxx|m|mm)$")

    SET(QT_FILES ${ARG_SOURCES})
    LIST(FILTER QT_FILES INCLUDE REGEX ".+\.(ui|qrc)$")

    FOREACH (HEADER ${HEADERS})
        GET_FILENAME_COMPONENT(HEADER_PATH ${HEADER} PATH)
        FILE(RELATIVE_PATH HEADER_PATH_REL ${ARG_PATH} "${HEADER_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" HEADER_PATH_REL_MSVC "${HEADER_PATH_REL}")
            SET(HEADER_PATH_REL "Header Files\\${HEADER_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${HEADER_PATH_REL}" FILES ${HEADER})
    ENDFOREACH ()

    FOREACH (SOURCE ${SOURCES})
        GET_FILENAME_COMPONENT(SOURCE_PATH "${SOURCE}" PATH)
        FILE(RELATIVE_PATH SOURCE_PATH_REL ${ARG_PATH} "${SOURCE_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" SOURCE_PATH_REL_MSVC "${SOURCE_PATH_REL}")
            SET(SOURCE_PATH_REL "Source Files\\${SOURCE_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${SOURCE_PATH_REL}" FILES "${SOURCE}")
    ENDFOREACH ()

    FOREACH (QT_FILE ${QT_FIELS})
        GET_FILENAME_COMPONENT(QT_FILE_PATH "${QT_FILE}" PATH)
        FILE(RELATIVE_PATH QT_FILE_PATH_REL ${ARG_PATH} "${QT_FILE_PATH}")
        IF (MSVC)
            STRING(REPLACE "/" "\\" QT_FILE_PATH_REL_MSVC "${QT_FILE_PATH_REL}")
            SET(QT_FILE_PATH_REL "QT Files\\${QT_FILE_PATH_REL_MSVC}")
        ENDIF ()
        SOURCE_GROUP("${QT_FILE_PATH_REL}" FILES "${QT_FILE}")
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GLOBAL_GROUP_SOURCES)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "RST" "PATHS" ${ARGN})
    SET(SOURCES "")
    FOREACH (PATH ${ARG_PATHS})
        FILE(GLOB_RECURSE PATH_SOURCES
                "${PATH}/*.h"
                "${PATH}/*.hpp"
                "${PATH}/*.hxx"
                "${PATH}/*.inl"
                "${PATH}/*.ipp"
                "${PATH}/*.tpp"
                "${PATH}/*.txx"
                "${PATH}/*.ixx"
                "${PATH}/*.c"
                "${PATH}/*.cpp"
                "${PATH}/*.cxx"
                "${PATH}/*.m"
                "${PATH}/*.mm"
                "${PATH}/*.in"
                "${PATH}/*.ui"
                "${PATH}/*.qrc"
        )
        LIST(APPEND SOURCES ${PATH_SOURCES})
        GROUP_SOURCES(PATH ${PATH} SOURCES ${SOURCES})
    ENDFOREACH ()
    SET(${ARG_RST} ${SOURCES} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(GET_TARGET_NAME RST TARGET_PATH)
    FILE(RELATIVE_PATH TARGET_RELATIVE_PATH "${CMAKE_SOURCE_DIR}/src" ${TARGET_PATH})
    STRING(REPLACE "/" "_" TARGET_NAME "${PROJECT_NAME}/${TARGET_RELATIVE_PATH}")
    SET(${RST} ${TARGET_NAME} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ADD_TARGET_GDR)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "MODE;QT;TEST" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})

    FILE(RELATIVE_PATH TARGET_RELATIVE_PATH "${CMAKE_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
    SET(FOLDER_PATH "${PROJECT_NAME}/${TARGET_RELATIVE_PATH}")
    GET_TARGET_NAME(TARGET_NAME ${CMAKE_CURRENT_SOURCE_DIR})

    LIST(LENGTH ARG_SOURCES SOURCE_NUM)
    IF (${SOURCE_NUM} EQUAL 0)
        GLOBAL_GROUP_SOURCES(RST ARG_SOURCES PATHS ${CMAKE_CURRENT_SOURCE_DIR})
        LIST(LENGTH ARG_SOURCES SOURCE_NUM)
        IF (SOURCE_NUM EQUAL 0)
            MESSAGE(WARNING "Target [${TARGET_NAME}] has no source files.")
            RETURN()
        ENDIF ()
    ENDIF ()

    MESSAGE(STATUS "--------------------------------------------------")

    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER: ${FOLDER_PATH}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    LIST_PRINT(STRS ${ARG_SOURCES}
            TITLE "- SOURCES:"
            PREFIX "  - "
    )

    LIST(LENGTH ARG_LIBS_GENERAL LIBS_GENERAL_NUM)
    LIST(LENGTH ARG_LIBS_DEBUG LIBS_DEBUG_NUM)
    LIST(LENGTH ARG_LIBS_RELEASE LIBS_RELEASE_NUM)
    IF (${LIBS_DEBUG_NUM} EQUAL 0 AND ${LIBS_RELEASE_NUM} EQUAL 0)
        IF (NOT ${LIBS_GENERAL_NUM} EQUAL 0)
            LIST_PRINT(STRS ${ARG_LIBS_GENERAL}
                    TITLE "- LIB:"
                    PREFIX "    "
            )
        ENDIF ()
    ELSE ()
        MESSAGE(STATUS "- LIBS:")
        LIST_PRINT(STRS ${ARG_LIBS_GENERAL}
                TITLE "  - GENERAL:"
                PREFIX "    "
        )
        LIST_PRINT(STRS ${ARG_LIBS_DEBUG}
                TITLE "  - DEBUG:"
                PREFIX "    "
        )
        LIST_PRINT(STRS ${ARG_LIBS_RELEASE}
                TITLE "  - RELEASE:"
                PREFIX "    "
        )
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
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
        SET(TARGETS ${TARGET_NAME})
    ELSEIF (${ARG_MODE} STREQUAL "DLL")
        ADD_LIBRARY(${TARGET_NAME} SHARED ${ARG_SOURCES})
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
        SET(TARGETS ${TARGER_NAME})
    ELSEIF (${ARG_MODE} STREQUAL "DS")
        ADD_LIBRARY("${TARGET_NAME}_shared" SHARED ${ARG_SOURCES})
        ADD_LIBRARY("My::${TARGET_NAME}_shared" ALIAS "${TARGET_NAME}_shared")
        ADD_LIBRARY("${TARGET_NAME}_static" STATIC ${ARG_SOURCES})
        ADD_LIBRARY("My::${TARGET_NAME}_static" ALIAS "${TARGET_NAME}_static")
        TARGET_COMPILE_DEFINITIONS("${TARGET_NAME}_shared" PUBLIC -DUBPA_STATIC)
        SET(TARGETS "${TARGET_NAME}_shared;${TARGET_NAME}_static")
    ELSE ()
        MESSAGE(FATAL_ERROR "Unknown mode: ${ARG_MODE}")
        RETURN()
    ENDIF ()

    FOREACH (TARGET ${TARGETS})
        SET_TARGET_PROPERTIES(${TARGET} PROPERTIES FOLDER ${FOLDER_PATH})

        FOREACH (LIB ${ARG_LIBS_GENERAL})
            TARGET_LINK_LIBRARIES(${TARGET_NAME} general ${LIB})
        ENDFOREACH ()
        FOREACH (LIB ${ARG_LIBS_DEBUG})
            TARGET_LINK_LIBRARIES(${TARGET_NAME} debug ${LIB})
        ENDFOREACH ()
        FOREACH (LIB ${ARG_LIBS_RELEASE})
            TARGET_LINK_LIBRARIES(${TARGET_NAME} optimized ${LIB})
        ENDFOREACH ()
        IF (NOT "${ARG_TEST}" STREQUAL "ON")
            INSTALL(TARGETS ${TARGET_NAME}
                    EXPORT "${PROJECT_NAME}Targets"
                    RUNTIME DESTINATION "bin"
                    ARCHIVE DESTINATION "lib"
                    LIBRARY DESTINATION "lib"
            )
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
    CMAKE_PARSE_ARGUMENTS("ARG" "" "INC" "" ${ARGN})
    # Install the configuration file.
    INSTALL(EXPORT "${PROJECT_NAME}Targets"
            FILE "${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )

    INCLUDE(CMakePackageConfigHelpers)

    # Generate the config file that is includes the exports.
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "lib/${PROJECT_NAME}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # Generate the version file for the config file.
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION "${Tutorial_VERSION_MAJOR}.${Tutorial_VERSION_MINOR}"
            COMPATIBILITY AnyNewerVersion
    )

    # Install the config files.
    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )

    # Generate the export targets for the build tree.
    # Needs to be after the install(TARGETS) command.
    EXPORT(EXPORT "${PROJECT_NAME}Targets"
            NAMESPACE "${PROJECT_NAME}::"
            FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
    )

    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${PROJECT_NAME}/cmake"
    )

    IF (NOT "${ARG_INC}" STREQUAL "OFF")
        INSTALL(DIRECTORY "include" DESTINATION ${CMAKE_INSTALL_PREFIX})
    ENDIF ()
ENDMACRO()
