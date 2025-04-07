# asics

### At Beginning

```cmake 
CMAKE_MINIMUM_REQUIRED(VERSION 3.20 FATAL_ERROR)
PROJECT(VERSION 1.2.3.4)
# CMAKE_PROJECT_NAME
# PROJECT_VERSION
# - PROJECT_VERSION_MAJOR
# - PROJECT_VERSION_MINOR
# - PROJECT_VERSION_PATCH
# - PROJECT_VERSION_TWEAK
# PROJECT_SOURCE_DIR
```

### Path Variables

- `<PROJECT_NAME>_BINARY_DIR` contains the `CMakeLists.txt` of `project()` in the subfolder `build/`
- `<PROJECT_NAME>_SOURCE_DIR`: the directory containing `CMakeLists.txt` of `project()`
- `CMAKE_BINARY_DIR`: `build/`
- `CMAKE_SOURCE_DIR`: The directory where the top-level `CMakeLists.txt` is located
- `CMAKE_CURRENT_BINARY_DIR`: `CMAKE_CURRENT_SOURCE_DIR` relative to `CMAKE_SOURCE_DIR` plus `<project_name>_SOURCE_DIR`
  inside `build/`
- `CMAKE_CURRENT_SOURCE_DIR`: The directory containing the currently processed `CMakeLists.txt` file
- `CMAKE_CURRENT_LIST_DIR`: The directory containing the currently processed CMake file
    - When using `include()`, this variable differs from `CMAKE_CURRENT_SOURCE_DIR`
    - When using `find_package()`, this variable typically differs from `CMAKE_CURRENT_SOURCE_DIR`

### Variables

- [SET](https://cmake.org/cmake/help/latest/command/set.html)

  ```cmake
  # Normal variable setting
  SET(<variable-name> <value>... [PARENT_SCOPE])
  
  # Cache variable setting
  SET(<variable-name> <value>... CACHE <type> <docstring> [FORCE])
  
  # Available types:
  # BOOL, FILEPATH, PATH, STRING
  
  # FORCE: Refreshes the cache value on every configure
  ```

- Variables need to distinguish between variable names and variable values, such as `var` and `${var}`
- Variables can be nested
  ```cmake
  SET(A_A aa)
  SET(var A)
  MESSAGE(STATUS "${A_${var}}") # aa
  ```

### Type

- [STRING](https://cmake.org/cmake/help/latest/command/string.html)
    - Basics
        - Format `"..."`, such as `"dd${var}dd"`, `"a string"`
        - Escape characters with double backslashes, such as `"...\\n..."`
        - Special characters with single backslash, such as `"...\"..."`
        - `${var}` is different from `"${var}"`
          ```cmake
          SET(SPECIAL_STR "aaa;bbb")
          
          # Example 1
          MESSAGE(STATUS ${SPECIAL_STR}) # aaabbb
          MESSAGE(STATUS "${SPECIAL_STR}") # aaa;bbb
          
          # Example 2
          FUNCTION(PRINT_VAR var)
            MESSAGE(STATUS "${var}")
          ENDFUNCTION()
          
          PRINT_VAR(${SPECIAL_STR}) # aaa
          PRINT_VAR("${SPECIAL_STR}") # aaa;bbb
          ```
    - FIND: `STRING(FIND <string> <substring> <output_variable> [REVERSE])`, the result is `-1` if not found
    - Manipulation
        ```cmake
        STRING(APPEND <string-var> [<input>...])
        STRING(PREPEND <string-var> [<input>...])
        STRING(CONCAT <out-var> [<input>...])
        STRING(JOIN <glue> <out-var> [<input>...])
        STRING(TOLOWER <string> <out-var>)
        STRING(TOUPPER <string> <out-var>)
        STRING(LENGTH <string> <out-var>)
        STRING(SUBSTRING <string> <begin> <length> <out-var>)
        STRING(STRIP <string> <out-var>)
        STRING(GENEX_STRIP <string> <out-var>)
        STRING(REPEAT <string> <count> <out-var>)
        ```
    - Comparison：`STRING(COMPARE <op> <string1> <string2> <out-var>)`
    - Hashing：`STRING(<HASH> <out-var> <input>)`
- [LIST](https://cmake.org/cmake/help/latest/command/list.html)
    - Create: `SET(<list_name> <item>...)` or `SET(<list_name> "${item_0};${item_1};...;${item_n}")`

### Debug

[MESSAGE](https://cmake.org/cmake/help/latest/command/message.html)

```cmake
MESSAGE(STATUS/WARNING/FATAL_ERROR "str")
```

### Function

- Passing parameters by name and by value
    ```cmake
    FUNCTION(PRINT_VAR var)
        MESSAGE(STATUS "${var}: ${${var}}")
    ENDFUNCTION()
    
    FUNCTION(PRINT_VALUE value)
        MESSAGE(STATUS "${value}")
    ENDFUNCTION()
    
    SET(num 3)
    PRINT_VAR(num)
    PRINT_VALUE(${num})
    ```

- [CMAKE_PARSE_ARGUMENTS](https://cmake.org/cmake/help/latest/command/cmake_parse_arguments.html)
    ```cmake
    CMAKE_PARSE_ARGUMENTS("ARG" # prefix
                          <options> # TRUE / FALSE
                          <one_value_keywords>
                          <multi_value_keywords> # list
                          ${ARGN})
    # Result: ARG_*
    # - ARG_<option>
    # - ARG_<one_value_keyword>
    # - ARG_<multi_value_keyword>
    ```
- `list` as parameter
    - `${list}` will be expanded into multiple parameters when calling
    - `"${list}"` is called, and the parameters inside the function are normal lists
    - `<list>` is called, and `${arg_list}` must be used inside the function to get a normal list

### Control Flow

- Loop n times
    ```cmake
    SET(i 0)
    WHILE (i LESS <n>)
      # ...
      MATH(EXPR i "${i} + 1")
    ENDWHILE ()
    ```
- Traverse one list
    ```cmake
    FOREACH (v ${list})
      # ... ${v}
    ENDFOREACH ()
    ```
- Traverse two lists of equal length
    ```cmake
    LIST(LENGTH <list0> n)
    SET(i 0)
    WHILE (i LESS n)
      LIST(GET <list0> ${i} v0)
      LIST(GET <list1> ${i} v1)
      # ...
      MATH(EXPR i "${i} + 1")
    ENDWHILE ()
    ```
- Traverse structure list
    ```cmake
    LIST(LENGTH <struct_list> n)
    SET(i 0)
    WHILE (i LESS n)
        LIST(SUBLIST <struct_list> ${i} <struct_size> <obj>)
        LIST(GET <obj> 0 <field_0>)
        LIST(GET <obj> 1 <field_1>)
        # ...
        LIST(GET <obj> k <field_k>) # k == <struct_size> - 1
    
        # ...
        MATH(EXPR i "${i} + ${struct_size}")
    ENDWHILE ()
    ```

### Regular Expression

- String
    ```cmake
    STRING(REGEX
        MATCH
        <regular_expression>
        <output_variable>
        <input> [<input>...])
    # Match once
    # CMAKE_MATCH_<n>
    # - captured by '()' syntax
    # - n : 0, 1, ..., 9
    # - CMAKE_MATCH_0 == <output_variable>
    # - n == CMAKE_MATCH_COUNT
    
    STRING(REGEX
        MATCHALL
        <regular_expression>
        <output_variable>
        <input> [<input>...])
    # Match multiple times, the result is a list
    # CMAKE_MATCH_* is not applicable here
    
    STRING(REGEX
        REPLACE
        <regular_expression>
        <replacement_expression>
        <output_variable>
        <input> [<input>...])
    # \1, \2, ..., \9 represent the result captured by '()'
    # In <replacement_expression>, they need to be written as \\1, \\2, ..., \\9
    ```
- List

    ```cmake
    list(FILTER <list>
            INCLUDE/EXCLUDE
            REGEX <regular_expression>)
    # INCLUDE: Keep only items matching the expression
    # EXCLUDE: Remove all items matching the expression
    ```

### Target

- Add:
  [ADD_EXECUTABLE](https://cmake.org/cmake/help/latest/command/add_executable.html), [ADD_LIBRARY](https://cmake.org/cmake/help/latest/command/add_library.html)
    ```cmake
    # 1. add target
      # 1.1 exe
      ADD_EXECUTABLE(<name> [<source>...])
    
      # 1.2 lib/dll
        # 1.2.1 normal
        ADD_LIBRARY(<name> STATIC|SHARED [<source>...])
        # 1.2.2 interface : e.g. pure header files
        ADD_LIBRARY(<name> INTERFACE)
    
    # 2. alias
    ADD_LIBRARY(<alias> ALIAS <target>)
    # <alias> can use the namespace <namespace>::<id>, such as My::XXX
    ```
- Source:

    ```cmake
    TARGET_SOURCES(<target>
            PUBLIC <item>...
            PRIVATE <item>...
            INTERFACE <item>...
    )
    
    # gather sources
    FILE(GLOB_RECURSE SOURCES
            # header files
            <path>/*.h
            <path>/*.hpp
            <path>/*.hxx
            <path>/*.inl
    
            # source files
            <path>/*.c
    
            <path>/*.cc
            <path>/*.cpp
            <path>/*.cxx
    
            # shader files
            <path>/*.vert # glsl vertex shader
            <path>/*.tesc # glsl tessellation control shader
            <path>/*.tese # glsl tessellation evaluation shader
            <path>/*.geom # glsl geometry shader
            <path>/*.frag # glsl fragment shader
            <path>/*.comp # glsl compute shader
    
            <path>/*.hlsl
    
            # Qt files
            <path>/*.qrc
            <path>/*.ui
    )
    
    # group
    FOREACH (SOURCE ${SOURCES})
        GET_FILENAME_COMPONENT(DIR ${SOURCE} DIRECTORY)
        IF (${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${DIR})
            SOURCE_GROUP("src" FILES ${SOURCE})
        ELSE ()
            FILE(RELATIVE_PATH RDIR ${PROJECT_SOURCE_DIR} ${DIR})
            IF (MSVC)
                STRING(REPLACE "/" "\\" RDIR_MSVC ${RDIR})
                SET(RDIR "${RDIR_MSVC}")
            ENDIF ()
            SOURCE_GROUP(${RDIR} FILES ${SOURCE})
        ENDIF ()
    ENDFOREACH ()
    ```
- Definition

    ```cmake
    TARGET_COMPILE_DEFINITIONS(<target>
            PUBLIC <item>...
            PRIVATE <item>...
            INTERFACE <item>...
    )
    # <item> => #define <item>
    ```

- Include directories

    ```cmake
    TARGET_INCLUDE_DIRECTORIES(MY_LIB PUBLIC
            $<BUILD_INTERFACE:<absolute_path>>
            $<INSTALL_INTERFACE:<relative_path>>  # <install_prefix>/<relative_path>
    )
    # e.g.
    # - <absolute_path>: ${PROJECT_SOURCE_DIR}/include
    # - <relative_path>: <package_name>/include
    ```

- Link library

    ```cmake
    TARGET_LINK_LIBRARIES(<target>
            PUBLIC <item>...
            PRIVATE <item>...
            INTERFACE <item>...
    )
    ```

### File

- Reading

    - READ: `FILE(READ <filename> <out>)`
    - STRINGS: `FILE(STRINGS <filename> <variable> [<options>...])`
    - HASH: `FILE(<HASH> <filename> <variable>)`
        - `<HASH>`：`MD5/SHA1/SHA224/SHA256/SHA384/SHA512/SHA3_224/SHA3_256/SHA3_384/SHA3_512`

- Writing

    - WRITE/APPEND: `FILE(WRITE/APPEND <filename> <content>...)`
    - TOUCH: `FILE(TOUCH [<files>...])`
        - If file does not exist, create an empty file
        - If file exists, update access and/or modification times
        - TOUCH_NOCREATE
    - GENERATE: `FILE(GENERATE OUTPUT <output_file> <INPUT input-file|CONTENT content>)`
        - Generate files in **generation phase**
        - Optionally add `CONDITION <expression>`, where `<expression> == 0/1`

- File system

    - GLOB
      ```cmake
        FILE(GLOB/GLOB_RECURSE <out_list>
            [LIST_DIRECTORIES true|false] # Include directories
            [RELATIVE <path>] # Relative path
            [CONFIGURE_DEPENDS] # Use all the result files as rebuild detection objects
            [<globbing-expressions>...] # Simplified regular expression
        )
      ```
    - `<globbing-expressions>`
        - ref: [Linux Programmer's Manual GLOB](http://man7.org/linux/man-pages/man7/glob.7.html)
        - `?`: matches a single character
        - `*`: matches any number of characters in the **file name/folder name**
        - `**`: matches any number of characters across directories
        - `[...]`: same as `[...]` in regular expressions
        - `[!...]`: complement

    - RENAME：`FILE(RENAME <oldname> <newname>)`, move a file or folder

    - REMOVE：`FILE(REMOVE/REMOVE_RECURSE [<files>...])`
        - `REMOVE`: Delete files, not folders

        - `REMOVE_RECURSE`: Delete files or folders
    - MAKE_DIRECTORY: `FILE(MAKE_DIRECTORY [<directories>...])`, recursively create folders

    - COPY/INSTALL: `FILE(COPY/INSTALL <files>... DESTINATION <dir>`, copy/install files

- Path conversion
    - `FILE(RELATIVE_PATH <variable> <directory> <file>)`
    - `FILE(TO_CMAKE_PATH "<path>" <variable>)`，`'/'`
    - `FILE(TO_NATIVE_PATH "<path>" <variable>)`，Windows `'\\'`，Others `'/'`
- Transfer
    - `FILE(DOWNLOAD <url> <file> [<options>...])`
        - `INACTIVITY_TIMEOUT <seconds>`: No response waiting time
        - `TIMEOUT <seconds>`: Total waiting time
        - `SHOW_PROGRESS`: Progress
        - `STATUS <variable>`: Status is a list of two values, the former is 0 for no error
        - `EXPECTED_HASH <HASH>=<value>`: Hash value

### Package

- `<namespace>`，e.g. `My`
- `<package_name>`
    - e.g. `${PROJECT_NAME}_${PROJECT_VERSION_MAJOR}_${PROJECT_VERSION_MINOR}_${PROJECT_VERSION_PATCH}`
- Target name: `${PROJECT_NAME}_${relative_path}`, where `/` should be converted to `_`
    - `STRING(REPLACE "/" "_" TARGET_NAME "${PROJECT_NAME}_${relative_path}")`
- bin, dll, lib path
    ```cmake
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/bin")
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/bin")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/lib")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/lib")
    ```
- Debug postfix
    - dll, lib: `SET(CMAKE_DEBUG_POSTFIX d)`
    - exe: `SET_TARGET_PROPERTIES(<target> PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})`
- Install

    ```cmake
    INSTALL(TARGETS <target>...
            EXPORT "${PROJECT_NAME}Targets" # link export
            RUNTIME DESTINATION bin # .exe, .dll
            LIBRARY DESTINATION "${package_name}/lib" # non-DLL shared library
            ARCHIVE DESTINATION "${package_name}/lib" # .lib
    )
    
    INSTALL(FILES "${PROJECT_SOURCE_DIR}/include" DESTINATION "${package_name}/include")
    ```    
- Install export

    ```cmake
    INSTALL(EXPORT "${PROJECT_NAME}Targets"
            NAMESPACE <namespace>
    )
    ```
- Config

    ```cmake
    INCLUDE(CMakePackageConfigHelpers)
    
    CONFIGURE_PACKAGE_CONFIG_FILE(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "${package_name}/cmake" # Only generate files for use, will need to install them later
            NO_SET_AND_CHECK_MACRO
            NO_CHECK_REQUIRED_COMPONENTS_MACRO
            PATH_VARS "${package_name}/include"
    )
    
    WRITE_BASIC_PACKAGE_VERSION_FILE(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY ExactVersion
    )
    
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
            ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
            DESTINATION "${PROJECT_NAME}/cmake"
    )
    ```

## Working with Visual Studio

- cmake -G "Visual Studio 16 2019" -A x64 -S ./ -B ./build