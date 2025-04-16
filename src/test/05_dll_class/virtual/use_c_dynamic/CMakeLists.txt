SET(LIBS "")
IF (MSVC)
    #
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    LIST(APPEND LIBS "dl")
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    LIST(APPEND LIBS "dl")
ENDIF ()

ADD_TARGET(
        TEST
        RET_TARGET_NAME tname
        MODE EXE
        LIB_PRIVATE
        ${LIBS}
)

ADD_DEPENDENCIES(${tname} MyCMake_test_05_dll_class_virtual_gen)
