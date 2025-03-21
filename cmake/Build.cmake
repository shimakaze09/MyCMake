MESSAGE(STATUS "Include Build.cmake")

FUNCTION(ADD_SUB_DIRS_REC PATH)
    FILE(GLOB_RECURSE CHILDREN LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${PATH}/*)
    SET(DIRS "")
    LIST(APPEND CHILDREN "${CMAKE_CURRENT_SOURCE_DIR}/${PATH}")
    FOREACH (ITEM ${CHILDREN})
        IF (IS_DIRECTORY ${ITEM} AND EXISTS "${ITEM}/CMakeLists.txt")
            LIST(APPEND DIRS ${ITEM})
        ENDIF ()
    ENDFOREACH ()
    FOREACH (DIR ${DIRS})
        ADD_SUBDIRECTORY(${DIR})
    ENDFOREACH ()
ENDFUNCTION()

FUNCTION(GET_TARGET_NAME RST TARGET_PATH)
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${TARGET_PATH}")
    STRING(REPLACE "/" "_" TARGET_NAME "${PROJECT_NAME}_${TARGET_REL_PATH}")
    SET(${RST} ${TARGET_NAME} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(EXPAND_SOURCES RST SOURCES)
    SET(TMP_RST "")
    FOREACH (ITEM ${${SOURCES}})
        IF (IS_DIRECTORY ${ITEM})
            FILE(GLOB_RECURSE ITEM_SRCS
                    # CMake
                    ${ITEM}/*.cmake

                    # msvc
                    ${ITEM}/*.natvis

                    # INTERFACE files
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

                    # ${ITEM}/*.hlsl
                    # ${ITEM}/*.hlsli
                    # ${ITEM}/*.fx
                    # ${ITEM}/*.fxh

                    # QT files
                    ${ITEM}/*.qrc
                    ${ITEM}/*.ui
            )
            LIST(APPEND TMP_RST ${ITEM_SRCS})
        ELSE ()
            IF (NOT IS_ABSOLUTE "${ITEM}")
                GET_FILENAME_COMPONENT(ITEM "${ITEM}" ABSOLUTE)
            ENDIF ()
            LIST(APPEND TMP_RST ${ITEM})
        ENDIF ()
    ENDFOREACH ()
    SET(${RST} ${TMP_RST} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ADD_TARGET)
    MESSAGE(STATUS "----------")

    SET(ARG_LIST "")
    # public
    LIST(APPEND ARG_LIST SOURCE_PUBLIC INC LIB DEFINE C_OPTION L_OPTION)
    # interface
    LIST(APPEND ARG_LIST SOURCE_INTERFACE INC_INTERFACE LIB_INTERFACE DEFINE_INTERFACE C_OPTION_INTERFACE L_OPTION_INTERFACE)
    # private
    LIST(APPEND ARG_LIST SOURCE INC_PRIVATE LIB_PRIVATE DEFINE_PRIVATE C_OPTION_PRIVATE L_OPTION_PRIVATE)
    CMAKE_PARSE_ARGUMENTS(
            "ARG"
            "TEST;QT;NOT_GROUP"
            "MODE;ADD_CURRENT_TO;OUTPUT_NAME;RET_TARGET_NAME"
            "${ARG_LIST}"
            ${ARGN}
    )

    # default
    IF ("${ARG_ADD_CURRENT_TO}" STREQUAL "")
        SET(ARG_ADD_CURRENT_TO "PRIVATE")
    ENDIF ()

    # public, private -> interface
    IF ("${ARG_MODE}" STREQUAL "INTERFACE")
        LIST(APPEND ARG_SOURCE_INTERFACE ${ARG_SOURCE_PUBLIC} ${ARG_SOURCE})
        LIST(APPEND ARG_INC_INTERFACE ${ARG_INC} ${ARG_INC_PRIVATE})
        LIST(APPEND ARG_LIB_INTERFACE ${ARG_LIB} ${ARG_LIB_PRIVATE})
        LIST(APPEND ARG_DEFINE_INTERFACE ${ARG_DEFINE} ${ARG_DEFINE_PRIVATE})
        LIST(APPEND ARG_C_OPTION_INTERFACE ${ARG_C_OPTION} ${ARG_C_OPTION_PRIVATE})
        LIST(APPEND ARG_L_OPTION_INTERFACE ${ARG_L_OPTION} ${ARG_L_OPTION_PRIVATE})
        SET(ARG_SOURCE_PUBLIC "")
        SET(ARG_SOURCE "")
        SET(ARG_INC "")
        SET(ARG_INC_PRIVATE "")
        SET(ARG_LIB "")
        SET(ARG_LIB_PRIVATE "")
        SET(ARG_DEFINE "")
        SET(ARG_DEFINE_PRIVATE "")
        SET(ARG_C_OPTION "")
        SET(ARG_C_OPTION_PRIVATE "")
        SET(ARG_L_OPTION "")
        SET(ARG_L_OPTION_PRIVATE "")

        IF (NOT "${ARG_ADD_CURRENT_TO}" STREQUAL "NONE")
            SET(ARG_ADD_CURRENT_TO "INTERFACE")
        ENDIF ()
    ENDIF ()

    # [option]
    # TEST
    # QT
    # NOT_GROUP
    # [value]
    # MODE: EXE / STATIC / SHARED / INTERFACE
    # ADD_CURRENT_TO: PUBLIC / INTERFACE / PRIVATE (default) / NONE
    # RET_TARGET_NAME
    # [list] : public, interface, private
    # SOURCE: dir(recursive), file, auto add current dir | target_sources
    # INC: dir                                           | target_include_directories
    # LIB: <lib-target>, *.lib                           | target_link_libraries
    # DEFINE: #define ...                                | target_compile_definitions
    # C_OPTION: compile options                          | target_compile_options
    # L_OPTION: link options                             | target_link_options

    # Test
    IF (ARG_TEST AND NOT "${BUILD_TEST_${PROJECT_NAME}}")
        RETURN()
    ENDIF ()

    IF (ARG_QT)
        QT_BEGIN()
    ENDIF ()

    # Sources
    IF ("${ARG_ADD_CURRENT_TO}" STREQUAL "PUBLIC")
        LIST(APPEND ARG_SOURCE_PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    ELSEIF ("${ARG_ADD_CURRENT_TO}" STREQUAL "INTERFACE")
        LIST(APPEND ARG_SOURCE_INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
    ELSEIF ("${ARG_ADD_CURRENT_TO}" STREQUAL "PRIVATE")
        LIST(APPEND ARG_SOURCE ${CMAKE_CURRENT_SOURCE_DIR})
    ELSEIF (NOT "${ARG_ADD_CURRENT_TO}" STREQUAL "NONE")
        MESSAGE(FATAL_ERROR "ADD_CURRENT_TO [${ARG_ADD_CURRENT_TO}] is not supported")
    ENDIF ()
    EXPAND_SOURCES(SOURCES_PUBLIC ARG_SOURCE_PUBLIC)
    EXPAND_SOURCES(SOURCES_INTERFACE ARG_SOURCE_INTERFACE)
    EXPAND_SOURCES(SOURCES_PRIVATE ARG_SOURCE)

    # Group
    IF (NOT NOT_GROUP)
        SET(ALL_SOURCES ${SOURCES_PUBLIC} ${SOURCES_INTERFACE} ${SOURCES_PRIVATE})
        FOREACH (SRC ${ALL_SOURCES})
            GET_FILENAME_COMPONENT(DIR ${SRC} DIRECTORY)
            STRING(FIND ${DIR} ${CMAKE_CURRENT_SOURCE_DIR} IDX)
            IF (NOT IDX EQUAL -1)
                SET(BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
                FILE(RELATIVE_PATH RDIR "${CMAKE_CURRENT_SOURCE_DIR}/.." ${DIR})
            ELSE ()
                SET(BASE_DIR ${PROJECT_SOURCE_DIR})
            ENDIF ()
            FILE(RELATIVE_PATH RDIR ${BASE_DIR} ${DIR})
            IF (MSVC)
                STRING(REPLACE "/" "\\" RDIR_MSVC ${RDIR})
                SET(RDIR "${RDIR_MSVC}")
            ENDIF ()
            SOURCE_GROUP(${RDIR} FILES ${SRC})
        ENDFOREACH ()
    ENDIF ()

    # Target folder
    FILE(RELATIVE_PATH TARGET_REL_PATH "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
    SET(TARGET_FOLDER "${PROJECT_NAME}/${TARGET_REL_PATH}")

    GET_TARGET_NAME(TARGET_NAME ${CMAKE_CURRENT_SOURCE_DIR})
    IF (NOT "${ARG_RET_TARGET_NAME}" STREQUAL "")
        SET(${ARG_RET_TARGET_NAME} ${TARGET_NAME} PARENT_SCOPE)
    ENDIF ()

    # Print
    MESSAGE(STATUS "- NAME: ${TARGET_NAME}")
    MESSAGE(STATUS "- FOLDER : ${TARGET_FOLDER}")
    MESSAGE(STATUS "- MODE: ${ARG_MODE}")
    LIST_PRINT(STRS ${SOURCES_PRIVATE}
            TITLE "- Sources (private):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${SOURCES_INTERFACE}
            TITLE "- Sources interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${SOURCES_PUBLIC}
            TITLE "- Sources public:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE}
            TITLE "- Define (public):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE_PRIVATE}
            TITLE "- Define interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE_INTERFACE}
            TITLE "- Define private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_LIB}
            TITLE "- Lib (public):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_LIB_INTERFACE}
            TITLE "- Lib interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_LIB_PRIVATE}
            TITLE "- Lib private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_INC}
            TITLE "- Inc:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_INC_INTERFACE}
            TITLE "- Inc interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_INC_PRIVATE}
            TITLE "- Inc private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE}
            TITLE "- Define (public):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE_INTERFACE}
            TITLE "- Define interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_DEFINE_PRIVATE}
            TITLE "- Define private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_C_OPTION}
            TITLE "- Compile option (public):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_C_OPTION_INTERFACE}
            TITLE "- Compile option interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_C_OPTION_PRIVATE}
            TITLE "- Compile option private:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_L_OPTION}
            TITLE "- Link option (public):"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_L_OPTION_INTERFACE}
            TITLE "- Link option interface:"
            PREFIX "  * ")
    LIST_PRINT(STRS ${ARG_L_OPTION_PRIVATE}
            TITLE "- Link option private:"
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
    ELSEIF ("${ARG_MODE}" STREQUAL "INTERFACE")
        ADD_LIBRARY(${TARGET_NAME} INTERFACE)
        ADD_LIBRARY("My::${TARGET_NAME}" ALIAS ${TARGET_NAME})
    ELSE ()
        MESSAGE(FATAL_ERROR "Mode [${ARG_MODE}] is not supported")
        RETURN()
    ENDIF ()

    # Folder
    IF (NOT ${ARG_MODE} STREQUAL "INTERFACE")
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES FOLDER ${TARGET_FOLDER})
    ENDIF ()

    # Target sources
    FOREACH (SRC ${SOURCES_PUBLIC})
        GET_FILENAME_COMPONENT(ABS_SRC ${SRC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_SRC ${PROJECT_SOURCE_DIR} ${ABS_SRC})
        TARGET_SOURCES(${TARGET_NAME} PUBLIC
                $<BUILD_INTERFACE:${ABS_SRC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_SRC}>
        )
    ENDFOREACH ()
    FOREACH (SRC ${SOURCES_PRIVATE})
        GET_FILENAME_COMPONENT(ABS_SRC ${SRC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_SRC ${PROJECT_SOURCE_DIR} ${ABS_SRC})
        TARGET_SOURCES(${TARGET_NAME} PRIVATE
                $<BUILD_INTERFACE:${ABS_SRC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_SRC}>
        )
    ENDFOREACH ()
    FOREACH (SRC ${SOURCES_INTERFACE})
        GET_FILENAME_COMPONENT(ABS_SRC ${SRC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_SRC ${PROJECT_SOURCE_DIR} ${ABS_SRC})
        TARGET_SOURCES(${TARGET_NAME} INTERFACE
                $<BUILD_INTERFACE:${ABS_SRC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_SRC}>
        )
    ENDFOREACH ()

    # Target define
    TARGET_COMPILE_DEFINITIONS(${TARGET_NAME}
            PUBLIC ${ARG_DEFINE}
            INTERFACE ${ARG_DEFINE_INTERFACE}
            PRIVATE ${ARG_DEFINE_PRIVATE}
    )

    # Target lib
    TARGET_LINK_LIBRARIES(${TARGET_NAME}
            PUBLIC ${ARG_LIB}
            INTERFACE ${ARG_LIB_INTERFACE}
            PRIVATE ${ARG_LIB_PRIVATE}
    )

    # Target inc
    FOREACH (INC ${ARG_INC})
        GET_FILENAME_COMPONENT(ABS_INC ${INC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_INC ${PROJECT_SOURCE_DIR} ${ABS_INC})
        TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PUBLIC
                $<BUILD_INTERFACE:${ABS_INC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_INC}>
        )
    ENDFOREACH ()
    FOREACH (INC ${ARG_INC_PRIVATE})
        GET_FILENAME_COMPONENT(ABS_INC ${INC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_INC ${PROJECT_SOURCE_DIR} ${ABS_INC})
        TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PRIVATE
                $<BUILD_INTERFACE:${ABS_INC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_INC}>
        )
    ENDFOREACH ()
    FOREACH (INC ${ARG_INC_INTERFACE})
        GET_FILENAME_COMPONENT(ABS_INC ${INC} ABSOLUTE)
        FILE(RELATIVE_PATH REL_INC ${PROJECT_SOURCE_DIR} ${ABS_INC})
        TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} INTERFACE
                $<BUILD_INTERFACE:${ABS_INC}>
                $<INSTALL_INTERFACE:${PACKAGE_NAME}/${REL_INC}>
        )
    ENDFOREACH ()

    # Target compile option
    TARGET_COMPILE_OPTIONS(${TARGET_NAME}
            PUBLIC ${ARG_C_OPTION}
            INTERFACE ${ARG_C_OPTION_INTERFACE}
            PRIVATE ${ARG_C_OPTION_PRIVATE}
    )

    # Target link option
    TARGET_LINK_OPTIONS(${TARGET_NAME}
            PUBLIC ${ARG_L_OPTION}
            INTERFACE ${ARG_L_OPTION_INTERFACE}
            PRIVATE ${ARG_L_OPTION_PRIVATE}
    )

    IF (NOT "${ARG_OUTPUT_NAME}" STREQUAL "")
        SET_TARGET_PROPERTIES(${TARGET_NAME} PROPERTIES OUTPUT_NAME "${ARG_OUTPUT_NAME}" CLEAN_DIRECT_OUTPUT 1)
    ENDIF ()

    IF (NOT ARG_TEST)
        INSTALL(TARGETS ${TARGET_NAME}
                EXPORT "${PROJECT_NAME}Targets"
                RUNTIME DESTINATION "bin"
                ARCHIVE DESTINATION "${PACKAGE_NAME}/lib"
                LIBRARY DESTINATION "${PACKAGE_NAME}/lib"
        )
    ENDIF ()

    IF (ARG_QT)
        QT_END()
    ENDIF ()

    MESSAGE(STATUS "----------")
ENDFUNCTION()