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

MACRO(ADD_DEP NAME VERSION)
    FIND_PACKAGE(${NAME} ${VERSION} EXACT QUIET)
    IF (${MyCMake_FOUND})
        MESSAGE(STATUS "${NAME}-${VERSION} found")
    ELSE ()
        MESSAGE(STATUS "${NAME}-${VERSION} not found, fetching...")
        FETCHCONTENT_DECLARE(
                ${NAME}
                GIT_REPOSITORY "https://github.com/shimakaze09/${NAME}"
                GIT_TAG "v${VERSION}"
        )
        FETCHCONTENT_MAKEAVAILABLE(${NAME})
        MESSAGE(STATUS "${NAME}-${VERSION} fetched")
    ENDIF ()
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "INC" "" ${ARGN})

    SET(PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")
    MESSAGE(STATUS "Export ${PACKAGE_NAME}")
    # Install the configuration targets
    INSTALL(EXPORT "${PROJECT_NAME}Targets"
            FILE "${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${package_name}/cmake"
    )

    INCLUDE(CMakePackageConfigHelpers)

    # generate the config file that is includes the exports
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "lib/${package_name}/cmake"
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

    # generate the version file for the config file
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
            COMPATIBILITY AnyNewerVersion
    )

    # install the configuration file
    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "lib/${package_name}/cmake"
    )

    # generate the export targets for the build tree
    # needs to be after the install(TARGETS ) command
    EXPORT(EXPORT "${PROJECT_NAME}Targets"
            NAMESPACE "${PROJECT_NAME}::"
            FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
    )

    INSTALL(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
            DESTINATION "lib/${package_name}/cmake"
    )

    IF (NOT "${ARG_INC}" STREQUAL "OFF")
        INSTALL(DIRECTORY "include" DESTINATION ${CMAKE_INSTALL_PREFIX})
    ENDIF ()
ENDMACRO()