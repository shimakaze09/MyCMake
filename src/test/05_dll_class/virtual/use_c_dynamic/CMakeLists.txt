SET(LIBS "")
IF(UNIX)
    LIST(APPEND LIBS "dl")
ELSEIF (WIN32)
    # On Windows, no additional libraries are needed for dynamic loading
ENDIF ()

ADD_TARGET(
        TEST
        RET_TARGET_NAME tname
        MODE EXE
        LIB_PRIVATE
        ${LIBS}
)

ADD_DEPENDENCIES(${tname} MyCMake_test_05_dll_class_virtual_gen)
