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

FUNCTION(DECODE_VERSION MAJOR MINOR PATCH VERSION)
    IF ("${VERSION}" MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(${MINOR} "${CMAKE_MATCH_2}" PARENT_SCOPE)
        set(${PATCH} "${CMAKE_MATCH_3}" PARENT_SCOPE)
    ELSEIF ("${VERSION}" MATCHES "^([0-9]+)\\.([0-9]+)")
        set(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(${MINOR} "${CMAKE_MATCH_2}" PARENT_SCOPE)
        set(${PATCH} "" PARENT_SCOPE)
    ELSE ()
        set(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(${MINOR} "" PARENT_SCOPE)
        set(${PATCH} "" PARENT_SCOPE)
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

MACRO(ADD_DEP NAME VERSION)
    SET(PACKAGE_HAS_DEPENDENCIES 1)
    LIST(FIND PACKAGE_DEP_NAME_LIST "${NAME}" IDX)
    IF ("${IDX}" STREQUAL "-1")
        MESSAGE(STATUS "Start add dependence ${NAME} v${VERSION}")
        SET(NEED_FIND TRUE)
    ELSE ()
        SET(A_VERSION "${${NAME}_VERSION}")
        SET(B_VERSION "${VERSION}")
        DECODE_VERSION(A_MAJOR A_MINOR A_PATCH "${A_VERSION}")
        DECODE_VERSION(B_MAJOR B_MINOR B_PATCH "${B_VERSION}")
        IF (("${A_MAJOR}" STREQUAL "${B_MAJOR}") AND ("${A_MINOR}" STREQUAL "${B_MINOR}"))
            MESSAGE(STATUS "Diamond dependence of ${NAME} with compatible version: ${A_VERSION} and ${B_VERSION}")
            IF ("${A_MAJOR}" LESS "${B_MAJOR}")
                LIST(REMOVE_AT PACKAGE_DEP_NAME_LIST ${IDX})
                LIST(REMOVE_AT PACKAGE_DEP_VERSION_LIST ${IDX})
                SET(NEED_FIND TRUE)
            ELSE ()
                SET(NEED_FIND FALSE)
            ENDIF ()
        ELSE ()
            MESSAGE(FATAL_ERROR "Diamond dependence of ${NAME} with incompatible version: ${A_VERSION} and ${B_VERSION}")
        ENDIF ()
    ENDIF ()
    IF ("${NEED_FIND}" STREQUAL TRUE)
        LIST(APPEND PACKAGE_DEP_NAME_LIST ${NAME})
        LIST(APPEND PACKAGE_DEP_VERSION_LIST ${VERSION})
        MESSAGE(STATUS "find package: ${name} v${version}")
        FIND_PACKAGE(${NAME} ${VERSION} QUIET)
        IF (${${NAME}_FOUND})
            MESSAGE(STATUS "${NAME} v${${NAME}_VERSION} found")
        ELSE ()
            SET(ADDRESS "https://github.com/shimakaze09/${NAME}.git")
            MESSAGE(STATUS "${NAME} v${VERSION} not found, fetching..."
                    "fetch: ${ADDRESS} with tag v${VERSION}")
            FETCHCONTENT_DECLARE(
                    ${NAME}
                    GIT_REPOSITORY ${ADDRESS}
                    GIT_TAG "v${VERSION}"
            )
            MESSAGE(STATUS "building ${NAME} v${VERSION}...")
            FETCHCONTENT_MAKEAVAILABLE(${NAME})
            MESSAGE(STATUS "${NAME} v${VERSION} built")
        ENDIF ()
    ENDIF ()
ENDMACRO()

MACRO(EXPORT_TARGETS)
    CMAKE_PARSE_ARGUMENTS("ARG" "" "TARGET" "DIRECTORIES" ${ARGN})

    PACKAGE_NAME(PACKAGE_NAME)
    MESSAGE(STATUS "${PACKAGE_NAME}")
    MESSAGE(STATUS "Export ${PACKAGE_NAME}")

    IF (${PACKAGE_HAS_DEPENDENCIES})
        SET(MY_PACKAGE_INIT "
        IF (NOT \${FETCHCONTENT_FOUND})
            INCLUDE(FETCHCONTENT)
        ENDIF ()
        IF (NOT \${MyCMake_FOUND})
            MESSAGE(STATUS \"Looking for package: MyCMake v${MyCMake_VERSION}\")
            FIND_PACKAGE(MyCMake ${MyCMake_VERSION} QUIET)
            IF (\${MyCMake_FOUND})
                MESSAGE(STATUS \"MyCMake v\${MyCMake_VERSION} found\")
            ELSE ()
                set(PACKAGE_ADDRESS \"https://github.com/shimakaze09/MyCMake.git\")
                MESSAGE(STATUS \"MyCMake v${MyCMake_VERSION} not found, fetching...\")
                MESSAGE(STATUS \"fetch: \${PACKAGE_ADDRESS} with tag v${MyCMake_VERSION}\")
                FetchContent_Declare(
                        MyCMake
                        GIT_REPOSITORY \${PACKAGE_ADDRESS}
                        GIT_TAG \"v${MyCMake_VERSION}\"
                )
                MESSAGE(STATUS \"Building MyCMake v${MyCMake_VERSION}...\")
                FETCHCONTENT_DECLARE(MyCMake)
                MESSAGE(STATUS \"MyCMake v${MyCMake_VERSION} built\")
            ENDIF ()
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
        STRING(REGEX MATCH "(.*)/" prefix ${DIR})
        IF ("${CMAKE_MATCH_1}" STREQUAL "")
            SET(DESTINATION "${PACKAGE_NAME}")
        ELSE ()
            SET(DESTINATION "${PACKAGE_NAME}/${CMAKE_MATCH_1}")
        ENDIF ()
        INSTALL(DIRECTORY ${DIR} DESTINATION "${DESTINATION}")
    ENDFOREACH ()
ENDMACRO()