IF (BUILD_TEST_MyCMake)
    CPMAddPackage(
            NAME nameof
            GITHUB_REPOSITORY Neargye/nameof
            GIT_TAG v0.9.4
    )
ENDIF ()

ADD_TARGET(
        TEST
        MODE EXE
        LIB nameof::nameof
)