# ---------------------------------------------------------------------
#
# ADD_DEP(<DEPENDENCY_LIST>)
#
# ---------------------------------------------------------------------
#
# EXPORT_TARGET([INC <INC>])
# - Export files
# - INC: default is "ON", install include/
#
# ---------------------------------------------------------------------

MESSAGE(STATUS "Include Package.cmake")

SET(${PROJECT_NAME}_HAS_DEPENDENCIES 0)

FUNCTION(DECODE_VERSION MAJOR MINOR PATCH VERSION)
    IF ("${VERSION}" MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        SET(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        SET(${MINOR} "${CMAKE_MATCH_2}" PARENT_SCOPE)
        SET(${PATCH} "${CMAKE_MATCH_3}" PARENT_SCOPE)
    ELSEIF ("${VERSION}" MATCHES "^([0-9]+)\\.([0-9]+)")
        SET(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        SET(${MINOR} "${CMAKE_MATCH_2}" PARENT_SCOPE)
        SET(${PATCH} "" PARENT_SCOPE)
    ELSE ()
        SET(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        SET(${MINOR} "" PARENT_SCOPE)
        SET(${PATCH} "" PARENT_SCOPE)
    ENDIF ()
ENDFUNCTION()

FUNCTION(TO_PACKAGE_NAME RST NAME VERSION)
    SET(TMP "${NAME}_${VERSION}")
    STRING(REPLACE "." "_" TMP ${TMP})
    SET(${RST} "${TMP}" PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(PACKAGE_NAME RST)
    TO_PACKAGE_NAME(TMP ${PROJECT_NAME} ${PROJECT_VERSION})
    SET(${RST} ${TMP} PARENT_SCOPE)
ENDFUNCTION()

MACRO(ADD_DEP_PROJECT PROJ_NAME NAME VERSION)
    SET(${PROJ_NAME}_HAS_DEPENDENCIES 1)
    LIST(FIND ${PROJ_NAME}_DEP_NAME_LIST ${NAME} IDX)
    IF ("${IDX}" STREQUAL "-1")
        MESSAGE(STATUS "Adding dependence ${NAME} v${VERSION}")
        SET(NEED_FIND TRUE)
    else ()
        SET(A_VERSION "${${NAME}_VERSION}")
        SET(B_VERSION "${VERSION}")
        DECODE_VERSION(A_MAJOR A_MINOR A_PATCH "${A_VERSION}")
        DECODE_VERSION(B_MAJOR B_MINOR B_PATCH "${B_VERSION}")
        IF ("${A_VERSION}" STREQUAL "${B_VERSION}")
            MESSAGE(STATUS "Diamond dependence of ${NAME} with same version: ${A_VERSION} and ${B_VERSION}")
            SET(NEED_FIND FALSE)
        ELSE ()
            MESSAGE(FATAL_ERROR "Diamond dependence of ${NAME} with incompatible version: ${A_VERSION} and ${B_VERSION}")
        ENDIF ()
    ENDIF ()
    IF ("${NEED_FIND}" STREQUAL TRUE)
        LIST(APPEND ${PROJ_NAME}_DEP_NAME_LIST ${NAME})
        LIST(APPEND ${PROJ_NAME}_DEP_VERSION_LIST ${VERSION})
        MESSAGE(STATUS "Finding: ${NAME} v${VERSION}")
        FIND_PACKAGE(${NAME} ${VERSION} QUIET)
        IF (${${NAME}_FOUND})
            MESSAGE(STATUS "${NAME} v${${NAME}_VERSION} found")
        ELSE ()
            SET(ADDRESS "https://github.com/shimakaze09/${NAME}")
            MESSAGE(STATUS "${NAME} v${VERSION} not found")
            MESSAGE(STATUS "Fetching from: ${ADDRESS} with tag v${VERSION}")
            FETCHCONTENT_DECLARE(
                    ${NAME}
                    GIT_REPOSITORY ${ADDRESS}
                    GIT_TAG "v${VERSION}"
            )
            FETCHCONTENT_MAKEAVAILABLE(${NAME})
            MESSAGE(STATUS "${NAME} v${VERSION} built")
        ENDIF ()
    ENDIF ()
ENDMACRO()

MACRO(ADD_DEP NAME VERSION)
    ADD_DEP_PROJECT(${PROJECT_NAME} ${NAME} ${VERSION})
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TARGET;INIT_TAIL" "DIRECTORIES" ${ARGN})

    PACKAGE_NAME(PKG_NAME)
    MESSAGE(STATUS "${PKG_NAME}")
    MESSAGE(STATUS "Exporting ${PKG_NAME}")

    IF (${${PROJECT_NAME}_HAS_DEPENDENCIES})
        SET(MY_PACKAGE_INIT "
                IF (NOT \${FETCHCONTENT_FOUND})
                    INCLUDE (FETCHCONTENT)
                ENDIF ()
                IF(NOT \${MyCMake_FOUND})
                    MESSAGE(STATUS \"Finding: MyCMake v${MyCMake_VERSION}\")
                    FIND_PACKAGE(MyCMake ${MyCMake_VERSION} QUITE)
                    IF(\${MyCMake_FOUND})
                        MESSAGE(STATUS \"MyCMake v\${MyCMake_VERSION} found.\")
                    ELSE()
                        SET(${PROJECT_NAME}_ADDRESS \"https://github.com/shimakaze09/MyCMake\")
                        MESSAGE(STATUS \"MyCMake v${MyCMake_VERSION} not found\")
                        FETCHCONTENT_DECLARE(
                            MyCMake
                            GIT_REPOSITORY \${${PROJECT_NAME}_ADDRESS}
                            GIT_TAG \"v${MyCMake_VERSION}\"
                        )
                        MESSAGE(STATUS: \"MyCMake v${MyCMake_VERSION} fetched, building...\")
                        FETCHCONTENT_MAKEAVAILABLE(MyCMake)
                        MESSAGE(STATUS \"MyCMake v${MyCMake_VERSION} built.\")
                    ENDIF()
                ENDIF ()
                ")

        IF ("${EXIST_${PROJECT_NAME}_NATVIS}" STREQUAL "TRUE")
            SET(PACKAGE_INIT "${PROJECT_INIT}
                IF (MSVC)
                    IF (EXISTS \"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}.natvis\")
                        IF (NOT \"\${EXIST_MY_NATVIS_EXE}\")
                            FILE (WRITE \"\${CMAKE_CURRENT_BINARY_DIR}/NatvisEmpty.cxx\" \"// generated by MyCMake for natvis\\nint main () { return 0; }\\n\")
                            ADD_EXECUTABLE (MY_NATVIS \"\${CMAKE_CURRENT_BINARY_DIR}/NatvisEmpty.cxx\")
                            SET (EXIST_MY_NATVIS_EXE \"ON\")
                        ENDIF ()
                        TARGET_SOURCES (My_natvis PRIVATE \"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}.natvis\")
                    ENDIF ()
                ENDIF ()
                ")
        ENDIF ()
        MESSAGE(STATUS " [Dependencies]")
        LIST(LENGTH ${PROJECT_NAME}_DEP_NAME_LIST ${PROJECT_NAME}_DEP_NUM)
        MATH(EXPR ${PROJECT_NAME}_STOP "${${PROJECT_NAME}_DEP_NUM}-1")
        FOREACH (INDEX RANGE ${${PROJECT_NAME}_STOP})
            LIST(GET ${PROJECT_NAME}_DEP_NAME_LIST ${INDEX} DEP_NAME)
            LIST(GET ${PROJECT_NAME}_DEP_VERSION_LIST ${INDEX} DEP_VERSION)
            MESSAGE(STATUS "- ${DEP_NAME} v${DEP_VERSION}")
            STRING(APPEND MY_PACKAGE_INIT "ADD_DEP_PROJECT(${PROJECT_NAME} ${DEP_NAME} ${DEP_VERSION}\n")
        ENDFOREACH ()
        STRING(APPEND MY_PACKAGE_INIT "\n${ARG_INIT_TAIL}")
    ENDIF ()

    IF (NOT "${ARG_TARGET}" STREQUAL "OFF")
        # Generate the export targets for the build tree
        # needs to be after the INSTALL(TARGETS) command
        EXPORT(EXPORT "${PROJECT_NAME}Targets"
                NAMESPACE "My::"
                # FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
        )

        # Install the configuration targets
        INSTALL(EXPORT "${PROJECT_NAME}Targets"
                FILE "${PROJECT_NAME}Targets.cmake"
                NAMESPACE "My::"
                DESTINATION "${PKG_NAME}/cmake"
        )
    ENDIF ()

    INCLUDE(CMakePackageConfigHelpers)
    # Generate the config file that is includes the exports
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "${PKG_NAME}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # Generate the version file for the config file
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY SameMinorVersion
    )

    # Install the configuration file
    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "${package_name}/cmake"
    )

    FOREACH (DIR ${ARG_DIRECTORIES})
        STRING(REGEX MATCH "(.*)/" PREFIX ${DIR})
        INSTALL(DIRECTORY ${DIR} DESTINATION "${PACKAGE_NAME}/${CMAKE_MATCH_1}")
    ENDFOREACH ()
ENDMACRO()