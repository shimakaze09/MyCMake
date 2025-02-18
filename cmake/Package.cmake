# ----------------------------------------------------------------------------
#
# ADD_DEP(<DEP-LIST>)
#
# ----------------------------------------------------------------------------
#
# EXPORT_TARGETS([INC <INC>])
# - Export some files
# - INC: default ON, install include/
#
# ----------------------------------------------------------------------------

MESSAGE(STATUS "Include Package.cmake")

SET(PACKAGE_HAS_DEPENDENCIES 0)

FUNCTION(TO_PACKAGE_NAME RST NAME VERSION)
    SET(TMP "${NAME}_${VERSION}")
    STRING(REPLACE "." "_" TMP ${TMP})
    SET(${RST} "${TMP}" PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(PACKAGE_NAME RST)
    TO_PACKAGE_NAME(TMP ${PROJECT_NAME} ${PROJECT_VERSION})
    SET(${RST} ${TMP} PARENT_SCOPE)
ENDFUNCTION()

MACRO(ADD_DEP NAME VERSION)
    SET(PACKAGE_HAS_DEPENDENCIES 1)
    LIST(APPEND PACKAGE_DEP_NAME_LIST ${NAME})
    LIST(APPEND PACKAGE_DEP_VERSION_LIST ${VERSION})
    MESSAGE(STATUS "Looking for: ${NAME} v${VERSION}")
    FIND_PACKAGE(${NAME} ${VERSION} QUIET)
    IF (${${NAME}_FOUND})
        MESSAGE(STATUS "${NAME} v${${NAME}_VERSION} found")
    ELSE ()
        set(ADDRESS "https://github.com/shimakaze09/${NAME}")
        message(STATUS "${NAME} v${${NAME}_VERSION} not found\n"
                "fetching ${ADDRESS} with tag v${VERSION}")
        FETCHCONTENT_DECLARE(
                ${NAME}
                GIT_REPOSITORY "${ADDRESS}"
                GIT_TAG "v${VERSION}"
        )
        MESSAGE(STATUS "Building ${NAME} v${VERSION}...")
        FETCHCONTENT_MAKEAVAILABLE(${NAME})
        MESSAGE(STATUS "${NAME} v${VERSION} built")
    ENDIF ()
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TARGET" "DIRECTORIES" ${ARGN})

    PACKAGE_NAME(PACKAGE_NAME)
    MESSAGE(STATUS "${PACKAGE_NAME}")
    MESSAGE(STATUS "Export ${PACKAGE_NAME}")

    IF (${PACKAGE_HAS_DEPENDENCIES})
        SET(MY_PACKAGE_INIT "
        IF (NOT ${FETCHCONTENT_FOUND})
            INCLUDE(FETCHCONTENT)
        ENDIF ()
        MESSAGE(STATUS \"Looking for: MyCMake v${MyCMake_VERSION}\")
        FIND_PACKAGE(MyCMake {MyCMake_VERSION} QUIET)
        IF (\${MyCMake_FOUND})
            MESSAGE(STATUS \"MyCMake v\${MyCMake_VERSION} found\")
        ELSE ()
            SET(PACKAGE_ADDRESS \"https://github.com/shimakaze09/MyCMake\")
            MESSAGE(STATUS \"MyCMake v{MyCMake_VERSION} not found.\")
            MESSAGE(STATUS \"Fetch: \${PACKAGE_ADDRESS} with tag v{MyCMake_VERSION}\")
            FETCHCONTENT_DECLARE(
                    MyCMake
                    GIT_REPOSITORY \${PACKAGE_ADDRESS}
                    GIT_TAG \"v{MyCMake_VERSION}\"
            )
            MESSAGE(STATUS \"Building MyCMake v{MyCMake_VERSION} ...\")
            FETCHCONTENT_MAKEAVAILABLE(MyCMake)
            MESSAGE(STATUS \"MyCMake v{MyCMake_VERSION} built\")
        ENDIF ()
        IF (MSVC)
            IF (EXISTS \"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}.natvis\")
                IF (NOT \"\${EXIST_MY_NATVIS_EXE}\")
                    ADD_EXECUTABLE(MY_NATVIS \"\${CMAKE_CURRENT_BINARY_DIR}/NatvisEmpty.cpp\")
                    SET(EXIST_MY_NATVIS_EXE \"ON\")
                ENDIF ()
                TARGET_SOURCES(MY_NATVIS PRIVATE \"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}.natvis\")
            ENDIF ()
        ENDIF ()")

        MESSAGE(STATUS "[DEPENDENCIES]")
        LIST(LENGTH PACKAGE_DEP_NAME_LIST PACKAGE_DEP_NUM)
        MATH(EXPR PACKAGE_STOP "${PACKAGE_DEP_NUM}-1")
        FOREACH (INDEX RANGE ${PACKAGE_STOP})
            LIST(GET PACKAGE_DEP_NAME_LIST ${INDEX} DEP_NAME)
            LIST(GET PACKAGE_DEP_VERSION_LIST ${INDEX} DEP_VERSION)
            MESSAGE(STATUS "- ${DEP_NAME} v${DEP_VERSION}")
            SET(MY_PACKAGE_INIT "${MY_PACKAGE_INIT}\nADD_DEP(${DEP_NAME} ${DEP_VERSION})")
        ENDFOREACH ()
    ENDIF ()

    IF (NOT "${ARG_TARGET}" STREQUAL "OFF")
        # Generate the export targets for the build tree
        # needs to be after the install(TARGETS) command
        EXPORT(EXPORT "${PROJECT_NAME}Targets"
                NAMESPACE "My::"
                # FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
        )

        # Install the configuration targets
        INSTALL(EXPORT "${PROJECT_NAME}Targets"
                FILE "${PROJECT_NAME}Targets.cmake"
                NAMESPACE "My::"
                DESTINATION "${PACKAGE_NAME}/cmake"
        )
    ENDIF ()

    INCLUDE(CMakePackageConfigHelpers)
    # Generate the config file that is includes the exports
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "${PACKAGE_NAME}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # generate the version file for the config file
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY SameMinorVersion
    )

    # Install the configuration file
    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "${PACKAGE_NAME}/cmake"
    )

    FOREACH (DIR ${ARG_DIRECTORIES})
        INSTALL(DIRECTORY ${DIR} DESTINATION ${PACKAGE_NAME})
    ENDFOREACH ()
ENDMACRO()