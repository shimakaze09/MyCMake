MESSAGE(STATUS "Include Build.cmake")

FUNCTION(ADD_SUB_DIRS_REC PATH)
    MESSAGE(STATUS "----------")
    FILE(GLOB_RECURSE CHILDREN LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${PATH}/*)
    SET(DIRS "")
    LIST(APPEND CHILDREN "${CMAKE_CURRENT_SOURCE_DIR}/${PATH}")
    FOREACH (ITEM ${CHILDREN})
        IF (IS_DIRECTORY ${ITEM} AND EXISTS "${ITEM}/CMakeLists.txt")
            LIST(APPEND DIRS ${ITEM})
        ENDIF ()
    ENDFOREACH ()
    LIST_PRINT(TITLE "Directories:" PREFIX "- " STRS ${DIRS})
    FOREACH (DIR ${DIRS})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GET_TARGET_NAME RST TARGET_PATH)
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${TARGET_PATH}")
    STRING(REPLACE "/" "_" TARGET_NAME "${PROJECT_NAME}_${TARGET_REL_PATH}")
    SET(${RST} ${TARGET_NAME} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ADD_TARGET)
    CMAKE_PARSE_ARGUMENTS("ARG" "TEST" "MODE;RET_TARGET_NAME" "SOURCE;INC;LIB;DEFINE;C_OPTION;INC_PRIVATE;LIB_PRIVATE;DEFINE_PRIVATE;C_OPTION_PRIVATE" ${ARGN})

    # [option]
    # TEST
    # [value]
    # MODE: EXE / STATIC / SHARED / HEAD
    # RET_TARGET_NAME
    # [list]
    # SOURCE: dir(recursive), file, auto add currunt dir | target_sources
    # INC: dir                                           | target_include_directories
    # LIB: <lib-target>, *.lib                           | target_link_libraries
    # DEFINE: #define ...                                | target_compile_definitions
    # C_OPTION: compile options

    # Test
    IF (ARG_TEST AND NOT "${BUILD${PROJECT_NAME}TEST}")
        RETURN()
    ENDIF ()

    # Sources
    SET(SOURCES "")
    LIST(APPEND ARG_SOURCE ${CMAKE_CURRENT_SOURCE_DIR})
    FOREACH (ITEM ${ARG_SOURCE})
        IF (IS_DIRECTORY ${ITEM})
            FILE(GLOB_RECURSE ITEM_SRCS
                    # CMake
                    ${ITEM}/*.cmake

                    # Header files
                    ${ITEM}/*.h
                    ${ITEM}/*.hpp
                    ${ITEM}/*.hxx
                    ${ITEM}/*.inl

                    # Source files
                    ${ITEM}/*.c

                    ${ITEM}/*.cc
                    ${ITEM}/*.cpp
                    ${ITEM}/*.cxx

                    # Shader files
                    ${ITEM}/*.vert # glsl vertex shader
                    ${ITEM}/*.tesc # glsl tessellation control shader
                    ${ITEM}/*.tese # glsl tessellation evaluation shader
                    ${ITEM}/*.geom # glsl geometry shader
                    ${ITEM}/*.frag # glsl fragment shader
                    ${ITEM}/*.comp # glsl compute shader

                    ${ITEM}/*.hlsl

                    # QT files
                    ${ITEM}/*.qrc
                    ${ITEM}/*.ui
            )
            LIST(APPEND SOURCES ${ITEM_SRCS})
        ELSE ()
            IF (NOT IS_ABSOLUTE ${ITEM})
                SET(ITEM "${CMAKE_CURRENT_LIST_DIR}/${ITEM}")
            ENDIF ()
            LIST(APPEND SOURCES ${ITEM})
        ENDIF ()
    ENDFOREACH ()

    # Group
    FOREACH (SOURCE ${SOURCES})
        GET_FILENAME_COMPONENT(DIR ${SOURCE} DIRECTORY)
        IF (${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${DIR})
            SOURCE_GROUP("src" FILES ${SOURCE})
        ELSE ()
            FILE(RELATIVE_PATH RDIR ${PROJECT_SOURCE_DIR} ${DIR})
            IF (MSVC)
                STRING(REPLACE "/" "\\" RDIR_MSVC ${RDIR})
                SET(RDIR "${RDIR_MSVC}")
            ENDIF ()
            SOURCE_GROUP(${RDIR} FILES ${SOURCE})
        ENDIF ()
    ENDFOREACH ()

    # Target folder
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
    SET(TARGET_FOLDER "${PROJECT_NAME}/${TARGET_REL_PATH}")

    GET_TARGET_NAME(TARGET_NAME ${CMAKE_CURRENT_SOURCE_DIR})
    IF (NOT "${ARG_RST_TARGET_NAME}" STREQUAL "")
        SET(${ARG_RET_TARGET_NAME} ${TARGET_NAME} PARENT_SCOPE)
    ENDIF ()

    # Print
    MESSAGE(STATUS "----------")
    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER : ${TARGET_FOLDER}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    LIST_PRINT(STRS ${ARG_DEFINE}
            TITLE "- Define:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE_PRIVATE}
            TITLE "- Define private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${SOURCES}
            TITLE "- Sources:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_LIB}
            TITLE "- Lib:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_LIB_PRIVATE}
            TITLE "- Lib private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_INC}
            TITLE "- Inc:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_INC_PRIVATE}
            TITLE "- Inc private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_C_OPTION}
            TITLE  "- Opt:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_C_OPTION_PRIVATE}
            TITLE  "- Opt private:"
            PREFIX "  * ")

    PACKAGE_NAME(PACKAGE_NAME)

    # Add target
    IF ("${ARG_MODE}" STREQUAL "EXE")
        ADD_EXECUTABLE(${TARGET_NAME})
        ADD_EXECUTABLE("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
        IF (MSVC)
            SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
        ENDIF ()
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
    ELSEIF ("${ARG_MODE}" STREQUAL "STATIC")
        ADD_LIBRARY(${TARGET_NAME} STATIC)
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
    ELSEIF ("${ARG_MODE}" STREQUAL "SHARED")
        ADD_LIBRARY(${TARGET_NAME} SHARED)
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
    ELSEIF ("${ARG_MODE}" STREQUAL "HEAD")
        ADD_LIBRARY(${TARGET_NAME} INTERFACE)
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
    ELSE ()
        MESSAGE(FATAL_ERROR "Mode [${ARG_MODE}] is not supported")
        RETURN()
    ENDIF ()

    # Folder
    IF (NOT ${ARG_MODE} STREQUAL "HEAD")
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES FOLDER ${TARGET_FOLDER})
    ENDIF ()

    # Target source
    IF (NOT ${ARG_MODE} STREQUAL "HEAD")
        TARGET_SOURCES(${TARGET_NAME} PRIVATE ${SOURCES})
    ELSE ()
        TARGET_SOURCES(${TARGET_NAME} INTERFACE ${SOURCES})
    ENDIF ()

    # Target define
    IF (NOT ${ARG_MODE} STREQUAL "HEAD")
        TARGET_COMPILE_DEFINITIONS(${TARGET_NAME}
                PUBLIC ${ARG_DEFINE}
                PRIVATE ${ARG_DEFINE_PRIVATE}
        )
    ELSE ()
        TARGET_COMPILE_DEFINITIONS(${TARGET_NAME} INTERFACE ${ARG_DEFINE} ${ARG_DEFINE_PRIVATE})
    ENDIF ()

    # Target lib
    IF (NOT ${ARG_MODE} STREQUAL "HEAD")
        TARGET_LINK_LIBRARIES(${TARGET_NAME}
                PUBLIC ${ARG_LIB}
                PRIVATE ${ARG_LIB_PRIVATE}
        )
    ELSE ()
        TARGET_LINK_LIBRARIES(${TARGET_NAME} INTERFACE ${ARG_LIB} ${ARG_LIB_PRIVATE})
    ENDIF ()

    # Target inc
    FOREACH (INC ${ARG_INC})
        IF (NOT ${ARG_MODE} STREQUAL "HEAD")
            TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PUBLIC
                    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/${INC}>
                    $<INSTALL_INTERFACE:${PACKAGE_NAME}/${INC}>
            )
        ELSE ()
            TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} INTERFACE
                    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/${INC}>
                    $<INSTALL_INTERFACE:${PACKAGE_NAME}/${INC}>
            )
        ENDIF ()
    ENDFOREACH ()
    FOREACH (INC ${ARG_INC_PRIVATE})
        IF (NOT ${ARG_MODE} STREQUAL "HEAD")
            TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PRIVATE
                    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/${INC}>
                    $<INSTALL_INTERFACE:${PACKAGE_NAME}/${INC}>
            )
        ELSE ()
            TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} INTERFACE
                    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/${INC}>
                    $<INSTALL_INTERFACE:${PACKAGE_NAME}/${INC}>
            )
        ENDIF ()
    ENDFOREACH ()

    # Target option
    IF(NOT ${ARG_MODE} STREQUAL "HEAD")
        TARGET_COMPILE_OPTIONS(${TARGET_NAME}
                PUBLIC ${ARG_C_OPTION}
                PRIVATE ${ARG_C_OPTION_PRIVATE}
        )
    ELSE ()
        TARGET_COMPILE_OPTIONS(${TARGET_NAME} INTERFACE ${ARG_C_OPTION} ${ARG_C_OPTION_PRIVATE})
    ENDIF ()

    IF (NOT ARG_TEST)
        INSTALL(TARGETS ${TARGET_NAME}
                EXPORT "${PROJECT_NAME}Targets"
                RUNTIME DESTINATION "bin"
                ARCHIVE DESTINATION "${PACKAGE_NAME}/lib"
                LIBRARY DESTINATION "${PACKAGE_NAME}/lib"
        )
    ENDIF ()
ENDFUNCTION()