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

SET(_PACKAGE_HAS_DEPENDENCIES 0)

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
    SET(_PACKAGE_HAS_DEPENDENCIES 1)
    LIST(APPEND PACKAGE_DEP_NAME_LIST ${NAME})
    LIST(APPEND PACKAGE_DEP_VERSION_LIST ${VERSION})
    MESSAGE(STATUS "Finding dependency: ${NAME} v${VERSION}")
    FIND_PACKAGE(${NAME} ${VERSION} QUIET)
    IF (${${NAME}_FOUND})
        MESSAGE(STATUS "${NAME} v${${NAME}_VERSION} found")
    else ()
        SET(ADDRESS "https://github.com/shimakaze09/${NAME}.git")
        MESSAGE(STATUS "${NAME} v${VERSION} not found, fetching ...\n"
                "Fetch from: ${ADDRESS} with tag v${version}")
        FetchContent_Declare(
                ${NAME}
                GIT_REPOSITORY ${ADDRESS}
                GIT_TAG "v${VERSION}"
        )
        MESSAGE(STATUS "Building ${NAME} v${VERSION}...")
        FETCHCONTENT_MAKEAVAILABLE(${NAME})
        MESSAGE(STATUS "Built: ${NAME} v${VERSION}")
    ENDIF ()
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TARGET" "DIRECTORIES" ${ARGN})

    PACKAGE_NAME(PKG_NAME)
    MESSAGE(STATUS "${PKG_NAME}")
    MESSAGE(STATUS "Exporting ${PKG_NAME}")

    IF (${_PACKAGE_HAS_DEPENDENCIES})
        SET(MY_PACKAGE_INIT "
IF (NOT ${FetchContent_FOUND})
	INCLUDE(FetchContent)
ENDIF ()
MESSAGE (STATUS \"find package: MyCMake v0.3.4\")
FIND_PACKAGE(MyCMake 0.3.4 QUIET)
IF(\${MyCMake_FOUND})
	MESSAGE(STATUS \"MyCMake v\${MyCMake_VERSION} found\")
ELSE()
	SET(PACKAGE_ADDRESS \"https://github.com/shimakaze09/MyCMake.git\")
	MESSAGE(STATUS \"UCMake v0.3.0 not found, so fetch it ...\")
	MESSAGE(STATUS \"fetch: \${PACKAGE_ADDRESS} with tag v0.3.4\")
	FETCHCONTENT_DECLARE(
	  MyCMake
	  GIT_REPOSITORY \${PACKAGE_ADDRESS}
	  GIT_TAG \"v0.3.4\"
	)
	MESSAGE(STATUS \"MyCMake v0.3.4 fetch done, building ...\")
	FETCHCONTENT_MAKEAVAILABLE(MyCMake)
	MESSAGE(STATUS \"MyCMake v0.3.4 build done\")
ENDIF()
")
        MESSAGE(STATUS "[Dependencies]")
        LIST(LENGTH _PACKAGE_DEP_NAME_LIST _PACKAGE_DEP_NUM)
        MATH(EXPR _PACKAGE_STOP "${_PACKAGE_DEP_NUM}-1")
        FOREACH (INDEX RANGE ${_PACKAGE_STOP})
            LIST(GET _PACKAGE_DEP_NAME_LIST ${INDEX} DEP_NAME)
            LIST(GET _PACKAGE_DEP_VERSION_LIST ${INDEX} DEP_VERSION)
            MESSAGE(STATUS "- ${DEP_NAME} v${DEP_VERSION}")
            SET(MY_PACKAGE_INIT "${MY_PACKAGE_INIT}\nADD_DEP(${DEP_NAME} ${DEP_VERSION})")
        ENDFOREACH ()
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
        INSTALL(DIRECTORY ${DIR} DESTINATION ${PKG_NAME})
    ENDFOREACH ()
ENDMACRO()