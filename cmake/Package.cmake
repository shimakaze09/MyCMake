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

MACRO(ADD_DEP)
    FIND_PACKAGE(${NAME} ${VERSION} EXACT QUIET)
    IF (${FOUND})
        MESSAGE(STATUS "${NAME} found: ${NAME}-${VERSION}")
    ELSE ()
        MESSAGE(STATUS "${NAME} not found, fetching...")
        FETCHCONTENT_DECLARE(
                ${NAME}
                GIT_REPOSITORY "https://github.com/shimakaze09/${NAME}.git"
                GIT_TAG "v${VERSION}"
        )
        FETCHCONTENT_MAKEAVAILABLE(${NAME})
        MESSAGE(STATUS "${NAME} fetched: ${NAME}-${VERSION}")
    ENDIF ()
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "INC;TARGET" "" ${ARGN})

    SET(PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")
    MESSAGE(STATUS "Exporting ${PACKAGE_NAME}")

    IF (NOT "${ARG_TARGET}" STREQUAL "OFF")
        # Generate the export targets for the build tree
        # needs to be after the INSTALL(TARGETS ) command
        EXPORT(EXPORT "${PROJECT_NAME}Targets"
                NAMESPACE "My::"
                FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
        )

        # Install the configuration targets
        INSTALL(EXPORT "${PROJECT_NAME}Targets"
                NAMESPACE "My::"
                DESTINATION "${PACKAGE_NAME}/cmake"
        )
    ENDIF ()

    INCLUDE(CMakePackageConfigHelpers)

    # Generate the config file that is includes the exports
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "${PACKAGE_NAME}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # Generate the version file for the config file
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
            COMPATIBILITY AnyNewerVersion
    )

    # Install the configuration file
    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "${package_name}/cmake"
    )

    IF (NOT "${ARG_INC}" STREQUAL "OFF")
        INSTALL(DIRECTORY "include" DESTINATION ${PACKAGE_NAME})
    ENDIF ()
ENDMACRO()