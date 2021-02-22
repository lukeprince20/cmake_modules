# Enable Static Analysis Tools supported directly by CMake
# Cmake will run the enabled analyzers along with each compiler command
# The output of these tools will be prefixed with "Warning:"

cmake_minimum_required(VERSION 3.9)

# clang-tidy - clang-based C++ linter tool which provides an extensible
# framework for diagnosing and fixing typical programming errors
option(ENABLE_CLANG_TIDY "Enable static analysis with clang-tidy" OFF)
set(CLANG_TIDY_ARGS "" CACHE STRING "clang-tidy arguments")

if(ENABLE_CLANG_TIDY)
    find_program(CLANG_TIDY_COMMAND clang-tidy)
    if(NOT CLANG_TIDY_COMMAND)
        message(FATAL_ERROR "clang-tidy requested but executable not found")
    endif()

    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_COMMAND} ${CLANG_TIDY_ARGS})

    # search current and parent directories for .clang-tidy
    set(CLANG_TIDY_SEARCH_PATHS ${CMAKE_CURRENT_SOURCE_DIR})
    set(PARENT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    while(NOT ${PARENT_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
        get_filename_component(PARENT_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
        list(APPEND CLANG_TIDY_SEARCH_PATHS ${PARENT_DIR})
    endwhile()
    unset(PARENT_DIR)

    find_file(CLANG_TIDY_CONFIG .clang-tidy
        PATHS ${CLANG_TIDY_SEARCH_PATHS}
        NO_DEFAULT_PATH)

    if(EXISTS ${CLANG_TIDY_CONFIG})
        # Create a compile definition that adds a build dependency on
        # .clang-tidy content so the compile command will change when
        # .clang-tidy changes. Targets adding this definition will rerun
        # clang-tidy on all sources even if sources haven't changed so long as
        # the checks have changed.
        # e.g. target_compile_definitions(MyLib PUBLIC ${CLANG_TIDY_DEFINITIONS})
        file(SHA1 ${CLANG_TIDY_CONFIG} CLANG_TIDY_SHA1)
        set(CLANG_TIDY_DEFINITIONS "CLANG_TIDY_SHA1=${CLANG_TIDY_SHA1}")
        unset(CLANG_TIDY_SHA1)
    endif()
endif()


# cppcheck - static analysis tool for C/C++ code that detects
# types of bugs compilers normally do not detect
option(ENABLE_CPPCHECK "Enable static analysis with cppcheck" OFF)
set(CPPCHECK_ARGS "" CACHE STRING "cppcheck arguments")

if(ENABLE_CPPCHECK)
    find_program(CPPCHECK_COMMAND cppcheck)
    if(NOT CPPCHECK_COMMAND)
        message(FATAL_ERROR "cppcheck requested but executable not found")
    endif()

    set(CMAKE_CXX_CPPCHECK ${CPPCHECK_COMMAND} ${CPPCHECK_ARGS})
endif()


# A C++ style checker following Google's C++ style guide
option(ENABLE_CPPLINT "Enable static analysis with cpplint" OFF)
set(CPPLINT_ARGS "" CACHE STRING "cpplint arguments")

if(ENABLE_CPPLINT)
    find_package(Python3 REQUIRED)
    find_program(CPPLINT_COMMAND cpplint)
    if(NOT CPPLINT_COMMAND)
        message(FATAL_ERROR "cpplint requested but script not found")
    endif()

    set(CMAKE_CXX_CPPLINT ${CPPLINT_COMMAND} ${CPPLINT_ARGS})
endif()

# include-what-you-use - parses C++ source files and determines the 
# exact include files required to compile that file
option(ENABLE_INCLUDE_WHAT_YOU_USE "Enable static analysis with include-what-you-use" OFF)
set(INCLUDE_WHAT_YOU_USE_ARGS "" CACHE STRING "include-what-you-use arguments")

if(ENABLE_INCLUDE_WHAT_YOU_USE)
    find_program(INCLUDE_WHAT_YOU_USE_COMMAND include-what-you-use)
    if(NOT INCLUDE_WHAT_YOU_USE_COMMAND)
        message(FATAL_ERROR "include-what-you-use requested but executable not found")
    endif()

    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE ${INCLUDE_WHAT_YOU_USE_COMMAND} ${INCLUDE_WHAT_YOU_USE_ARGS})
endif()

# link-what-you-use - built in CMake feature that uses
# options of ld and ldd to print out if executables 
# link more libraries than they actually require
option(ENABLE_LINK_WHAT_YOU_USE "Enable static analysis with link-what-you-use" OFF)

if(ENABLE_LINK_WHAT_YOU_USE)
    if(UNIX AND NOT APPLE)
        set(CMAKE_LINK_WHAT_YOU_USE TRUE) 
    else()
        message(WARNING "link-what-you-use requested but disabled for Apple platforms")
    endif()
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # Required by most static analysis tools
