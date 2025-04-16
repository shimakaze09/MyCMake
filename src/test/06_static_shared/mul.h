#if (defined(WIN32) || defined(_WIN32)) && \
    !defined(MYCMAKE_STATIC_MyCMake_test_06_static_shared_gen)
#ifdef MYCMAKE_EXPORT_MyCMake_test_06_static_shared_gen
#define MyCMake_test_06_static_shared_gen_API __declspec(dllexport)
#else
#define MyCMake_test_06_static_shared_gen_API __declspec(dllimport)
#endif
#else
#define MyCMake_test_06_static_shared_gen_API extern
#endif  // (defined(WIN32) || defined(_WIN32)) &&
        // !defined(MYCMAKE_STATIC_MyCMake_test_06_static_shared_gen)

#ifdef __cplusplus
extern "C" {
#endif

MyCMake_test_06_static_shared_gen_API int mul(int a, int b);

#ifdef __cplusplus
}
#endif
