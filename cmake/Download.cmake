MESSAGE(STATUS "Include Download.cmake")

FUNCTION(IS_NEED_DOWNLOAD RST FILENAME HASH_TYPE HASH)
    IF (EXISTS ${FILENAME})
        FILE(${HASH_TYPE} ${FILENAME} ORIG_FILE_HASH)
        STRING(TOLOWER ${HASH} LHASH)
        STRING(TOLOWER ${ORIG_FILE_HASH} LORIG_FILE_HASH)
        IF (${LHASH} STREQUAL ${LORIG_FILE_HASH})
            SET(${RST} "FALSE" PARENT_SCOPE)
            RETURN()
        ENDIF ()
    ENDIF ()

    SET(${RST} "TRUE" PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(DOWNLOAD_FILE URL FILENAME HASH_TYPE HASH)
    IS_NEED_DOWNLOAD(NEED ${FILENAME} ${HASH_TYPE} ${HASH})
    IF (${NEED} STREQUAL "FALSE")
        MESSAGE(STATUS "Found File: ${FILENAME}")
        RETURN()
    ENDIF ()
    STRING(REGEX MATCH ".*/" DIR ${FILENAME})
    FILE(MAKE_DIRECTORY ${DIR})
    MESSAGE(STATUS "Download File: ${FILENAME}")
    FILE(DOWNLOAD ${URL} ${FILENAME}
            TIMEOUT 60  # seconds
            EXPECTED_HASH ${HASH_TYPE}=${HASH}
            TLS_VERIFY ON)
ENDFUNCTION()

FUNCTION(DOWNLOAD_ZIP URL ZIP_NAME HASH_TYPE HASH)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${PROJECT_NAME}/${ZIP_NAME}")
    IS_NEED_DOWNLOAD(NEED ${FILENAME} ${HASH_TYPE} ${HASH})
    IF (${NEED} STREQUAL "FALSE")
        MESSAGE(STATUS "Found File: ${ZIP_NAME}")
        RETURN()
    ENDIF ()
    MESSAGE(STATUS "Download File: ${ZIP_NAME}")
    FILE(DOWNLOAD ${URL} ${FILENAME}
            TIMEOUT 60  # seconds
            EXPECTED_HASH ${HASH_TYPE}=${HASH}
            TLS_VERIFY ON)
    # This is OS-agnostic
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E tar -xf ${FILENAME}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
ENDFUNCTION()

FUNCTION(DOWNLOAD_ZIP_PRO URL ZIP_NAME DIR HASH_TYPE HASH)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${PROJECT_NAME}/${ZIP_NAME}")
    IS_NEED_DOWNLOAD(NEED ${FILENAME} ${HASH_TYPE} ${HASH})
    IF (${NEED} STREQUAL "FALSE")
        MESSAGE(STATUS "Found File: ${ZIP_NAME}")
        RETURN()
    ENDIF ()
    MESSAGE(STATUS "Download File: ${ZIP_NAME}")
    FILE(DOWNLOAD ${URL} ${FILENAME}
            TIMEOUT 60  # seconds
            EXPECTED_HASH ${HASH_TYPE}=${HASH}
            TLS_VERIFY ON)
    # this is OS-agnostic
    FILE(MAKE_DIRECTORY ${DIR})
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E tar -xf ${FILENAME}
            WORKING_DIRECTORY ${DIR})
ENDFUNCTION()

FUNCTION(DOWNLOAD_TEST_FILE URL FILENAME HASH_TYPE HASH)
    IF ("${BUILD_TEST}" STREQUAL "OFF" OR "${BUILD_TEST}" STREQUAL "")
        RETURN()
    ENDIF ()
    DOWNLOAD_FILE(${URL} ${FILENAME} ${HASH_TYPE} ${HASH})
ENDFUNCTION()

FUNCTION(DOWNLOAD_TEST_ZIP URL ZIP_NAME HASH_TYPE HASH)
    IF ("${BUILD_TEST}" STREQUAL "OFF" OR "${BUILD_TEST}" STREQUAL "")
        RETURN()
    ENDIF ()
    DOWNLOAD_ZIP(${URL} ${ZIP_NAME} ${HASH_TYPE} ${HASH})
ENDFUNCTION()

FUNCTION(DOWNLOAD_TEST_ZIP_PRO URL ZIP_NAME DIR HASH_TYPE HASH)
    IF ("${BUILD_TEST}" STREQUAL "OFF" OR "${BUILD_TEST}" STREQUAL "")
        RETURN()
    ENDIF ()
    DOWNLOAD_ZIP_PRO(${URL} ${ZIP_NAME} ${DIR} ${HASH_TYPE} ${HASH})
ENDFUNCTION()