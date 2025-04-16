#if (defined(WIN32) || defined(_WIN32)) && \
    !defined(MyCMake_test_05_dll_class_classic_gen_STATIC)
#ifdef MyCMake_test_05_dll_class_classic_gen_EXPORTS
#define MyCMake_test_05_dll_class_classic_gen_API __declspec(dllexport)
#define MyCMake_test_05_dll_class_classic_gen_CLASS_API __declspec(dllexport)
#else
#define MyCMake_test_05_dll_class_classic_gen_API __declspec(dllimport)
#define MyCMake_test_05_dll_class_classic_gen_CLASS_API __declspec(dllimport)
#endif
#else
#define MyCMake_test_05_dll_class_classic_gen_API extern
#define MyCMake_test_05_dll_class_classic_gen_CLASS_API
#endif  // (defined(WIN32) || defined(_WIN32)) && !defined(MyCMake_test_05_dll_class_classic_gen_STATIC)

#include <stddef.h>

#ifdef __cplusplus
#include <type_traits>

class MyCMake_test_05_dll_class_classic_gen_CLASS_API MyClass {
 public:
  int x;
  int y;

  MyClass();
  ~MyClass();
  void SayHello() const;
};

static_assert(std::is_standard_layout_v<MyClass>);
using MyClassHandle = MyClass*;
using MyClassConstHandle = const MyClass*;
#else
typedef struct {
  int x;
  int y;
} MyClass;

typedef MyClass* MyClassHandle;
typedef const MyClass* MyClassConstHandle;
#endif

#ifdef __cplusplus
extern "C" {
#endif

MyCMake_test_05_dll_class_classic_gen_API size_t sizeof_MyClass();
MyCMake_test_05_dll_class_classic_gen_API MyClassHandle
MyClass_Construct(void* addr);
MyCMake_test_05_dll_class_classic_gen_API void MyClass_Destruct(
    MyClassHandle h);
MyCMake_test_05_dll_class_classic_gen_API void MyClass_SayHello(
    MyClassConstHandle h);

#ifdef __cplusplus
}
#endif
