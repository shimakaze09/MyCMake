#if (defined(WIN32) || defined(_WIN32)) && \
    !defined(MYCMAKE_STATIC_MyCMake_test_04_dll)
#ifdef MYCMAKE_EXPORT_MyCMake_test_04_dll_gen
#define MyCMake_test_04_dll_gen_API __declspec(dllexport)
#else
#define MyCMake_test_04_dll_gen_API __declspec(dllimport)
#endif
#else
#define MyCMake_test_04_dll_gen_API extern
#endif  // (defined(WIN32) || defined(_WIN32)) &&
        // !defined(MyCMake_test_04_dll_STATIC)

#ifdef __cplusplus
extern "C" {
#endif

MyCMake_test_04_dll_gen_API int mul(int a, int b);

#ifdef __cplusplus
}
#endif
