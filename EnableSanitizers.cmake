#[=======================================================================[.rst:
EnableSanitizers
----------------

Enable compiler and linker sanitizer flags for a project.

Support for the following sanitizers is provided:

- Address Sanitizer (asan)
- Thread Sanitizer (tsan)
- Memory Sanitizer (msan)
- Undefined Behavior Sanitizer (ubsan)
- Leak Sanitizer (lsan)

The following variables are respected by this module:

.. variable:: ENABLE_SANITIZERS

  List of sanitizers to enable.

Usage
=====

Include the ``EnableSanitizers.cmake` module in your project's ``CMakeLists.txt``

    include(EnableSanitizers)

To check if a sanitizers (asan, tsan, etc.) is available:

    check_cxx_<sanitizer>()

To check all sanitizers:

    check_cxx_sanitizers()

To add the compile and link options for a list of sanitizers in your project:

    add_cxx_sanitizers()

which will check the list of sanitizers in the CACHE variable ``ENABLE_SANITIZERS``
and add the appropriate compile and link options to the project for each.

.. note::

  The "address", "memory", and "thread" sanitizers are mutually exclusive.
  That is, only one may be used in a build.

.. note::

  The "thread" sanitizer requires the compiler to support position-independent code
  (PIC) and the check performed requires the compiler to additionally support
  position-independent executables (PIE).

#]=======================================================================]


cmake_minimum_required(VERSION 3.14)

include(CheckCXXSourceCompiles)

### CACHE Variables ###

set(ENABLE_SANITIZERS "" CACHE STRING "List of sanitizers to enable")
set_property(CACHE ENABLE_SANITIZERS PROPERTY STRINGS "address;thread;memory;undefined;leak")

### Check Address Sanitizer ###

set(_ENABLE_SANITIZERS_ASAN_COMPILE_OPTIONS -fsanitize=address -fno-omit-frame-pointer)
set(_ENABLE_SANITIZERS_ASAN_LINK_OPTIONS -fsanitize=address)

function(check_cxx_asan)
  unset(CMAKE_CXX_ADDRESS_SANITIZER_FOUND CACHE) 
  set(CMAKE_REQUIRED_FLAGS ${_ENABLE_SANITIZERS_ASAN_COMPILE_OPTIONS})
  set(CMAKE_REQUIRED_LINK_OPTIONS ${_ENABLE_SANITIZERS_ASAN_LINK_OPTIONS})
  check_cxx_source_compiles("int main(){}" CMAKE_CXX_ADDRESS_SANITIZER_FOUND)
endfunction()

### Check Thread Sanitizer ###

set(_ENABLE_SANITIZERS_TSAN_COMPILE_OPTIONS -fsanitize=thread)
set(_ENABLE_SANITIZERS_TSAN_LINK_OPTIONS -fsanitize=thread)

function(check_cxx_tsan)
  include(CheckPIESupported)
  check_pie_supported(OUTPUT_VARIABLE output LANGUAGES CXX)
  if(NOT CMAKE_CXX_LINK_PIE_SUPPORTED)
    message(WARNING "PIE is not supported at link time: ${output}. "
                    "PIE link options will not be passed to linker.")
  endif()

  unset(CMAKE_CXX_THREAD_SANITIZER_FOUND CACHE) 
  set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
  set(CMAKE_REQUIRED_FLAGS ${_ENABLE_SANITIZERS_TSAN_COMPILE_OPTIONS})
  set(CMAKE_REQUIRED_LINK_OPTIONS ${_ENABLE_SANITIZERS_TSAN_LINK_OPTIONS})
  check_cxx_source_compiles("int main(){}" CMAKE_CXX_THREAD_SANITIZER_FOUND)
endfunction()

### Check Memory Sanitizer ###

set(_ENABLE_SANITIZERS_MSAN_COMPILE_OPTIONS -fsanitize=memory -fno-omit-frame-pointer -fno-optimize-sibling-calls)
set(_ENABLE_SANITIZERS_MSAN_LINK_OPTIONS -fsanitize=memory)

function(check_cxx_msan)
  unset(CMAKE_CXX_MEMORY_SANITIZER_FOUND CACHE) 
  set(CMAKE_REQUIRED_FLAGS ${_ENABLE_SANITIZERS_MSAN_COMPILE_OPTIONS})
  set(CMAKE_REQUIRED_LINK_OPTIONS ${_ENABLE_SANITIZERS_MSAN_LINK_OPTIONS})
  check_cxx_source_compiles("int main(){}" CMAKE_CXX_MEMORY_SANITIZER_FOUND)
endfunction()

### Check Undefined Behavior Sanitizer ###

set(_ENABLE_SANITIZERS_UBSAN_COMPILE_OPTIONS -fsanitize=undefined -fno-omit-frame-pointer)
set(_ENABLE_SANITIZERS_UBSAN_LINK_OPTIONS -fsanitize=undefined)

function(check_cxx_ubsan)
  unset(CMAKE_CXX_UNDEFINED_BEHAVIOR_SANITIZER_FOUND CACHE) 
  set(CMAKE_REQUIRED_FLAGS ${_ENABLE_SANITIZERS_UBSAN_COMPILE_OPTIONS})
  set(CMAKE_REQUIRED_LINK_OPTIONS ${_ENABLE_SANITIZERS_UBSAN_LINK_OPTIONS})
  check_cxx_source_compiles("int main(){}" CMAKE_CXX_UNDEFINED_BEHAVIOR_SANITIZER_FOUND)
endfunction()

### Check Leak Sanitizer ###

set(_ENABLE_SANITIZERS_LSAN_COMPILE_OPTIONS -fsanitize=leak)
set(_ENABLE_SANITIZERS_LSAN_LINK_OPTIONS -fsanitize=leak)

function(check_cxx_lsan)
  unset(CMAKE_CXX_LEAK_SANITIZER_FOUND CACHE) 
  set(CMAKE_REQUIRED_FLAGS ${_ENABLE_SANITIZERS_LSAN_COMPILE_OPTIONS})
  set(CMAKE_REQUIRED_LINK_OPTIONS ${_ENABLE_SANITIZERS_LSAN_LINK_OPTIONS})
  check_cxx_source_compiles("int main(){}" CMAKE_CXX_LEAK_SANITIZER_FOUND)
endfunction()

### Check All Sanitizers ###

macro(check_cxx_sanitizers)
  check_cxx_asan()
  check_cxx_tsan()
  check_cxx_msan()
  check_cxx_ubsan()
  check_cxx_lsan()
endmacro()

### Add Sanitizers ###

function(add_cxx_sanitizers)
  if(NOT ENABLE_SANITIZERS STREQUAL "")
    list(TRANSFORM ENABLE_SANITIZERS TOLOWER OUTPUT_VARIABLE _requested_sanitizers)
    list(REMOVE_DUPLICATES _requested_sanitizers)
    _enable_sanitizers_check_mutually_exclusive(_requested_sanitizers)

    foreach(_sanitizer ${_requested_sanitizers})
      if(_sanitizer STREQUAL "address")
        check_cxx_asan()
        if($CACHE{CMAKE_CXX_ADDRESS_SANITIZER_FOUND})  
          add_compile_options(${_ENABLE_SANITIZERS_ASAN_COMPILE_OPTIONS})
          add_link_options(${_ENABLE_SANITIZERS_ASAN_LINK_OPTIONS})
	else()
          message(FATAL_ERROR "The address sanitizer is not supported by your compiler, "
			      "or the required libraries are not available.")
        endif()

      elseif(_sanitizer STREQUAL "thread")
        check_cxx_tsan()
        if($CACHE{CMAKE_CXX_THREAD_SANITIZER_FOUND})  
          add_compile_options(${_ENABLE_SANITIZERS_TSAN_COMPILE_OPTIONS})
          add_link_options(${_ENABLE_SANITIZERS_TSAN_LINK_OPTIONS})
	else()
          message(FATAL_ERROR "The thread sanitizer is not supported by your compiler, "
			      "or the required libraries are not available.")
        endif()

      elseif(_sanitizer STREQUAL "memory")
        check_cxx_msan()
        if($CACHE{CMAKE_CXX_MEMORY_SANITIZER_FOUND})  
          add_compile_options(${_ENABLE_SANITIZERS_MSAN_COMPILE_OPTIONS})
          add_link_options(${_ENABLE_SANITIZERS_MSAN_LINK_OPTIONS})
	else()
          message(FATAL_ERROR "The memory sanitizer is not supported by your compiler, "
			      "or the required libraries are not available.")
        endif()

      elseif(_sanitizer STREQUAL "undefined")
        check_cxx_ubsan()
        if($CACHE{CMAKE_CXX_UNDEFINED_BEHAVIOR_SANITIZER_FOUND})  
          add_compile_options(${_ENABLE_SANITIZERS_UBSAN_COMPILE_OPTIONS})
          add_link_options(${_ENABLE_SANITIZERS_UBSAN_LINK_OPTIONS})
	else()
          message(FATAL_ERROR "The undefined behavior sanitizer is not supported by your compiler, "
			      "or the required libraries are not available.")
        endif()

      elseif(_sanitizer STREQUAL "leak")
        check_cxx_lsan()
        if($CACHE{CMAKE_CXX_LEAK_SANITIZER_FOUND})  
          add_compile_options(${_ENABLE_SANITIZERS_LSAN_COMPILE_OPTIONS})
          add_link_options(${_ENABLE_SANITIZERS_LSAN_LINK_OPTIONS})
	else()
          message(FATAL_ERROR "The leak sanitizer is not supported by your compiler, "
			      "or the required libraries are not available.")
        endif()

      else()
        get_property(_supported_sanitizers CACHE ENABLE_SANITIZERS PROPERTY STRINGS)
        message(FATAL_ERROR "Sanitizer `${_sanitizer}` not a supported sanitizer `${_supported_sanitizers}`")
      endif()
    endforeach() 
  endif()
endfunction()

function(_enable_sanitizers_check_mutually_exclusive sanitizers)
  set(mutually_exclusive_sanitizers "address;thread;memory")
  set(requested_me_sanitizers)
  foreach(_sanitizer ${${sanitizers}})
    if(${_sanitizer} IN_LIST mutually_exclusive_sanitizers)
      list(APPEND requested_me_sanitizers ${_sanitizer})
    endif()
  endforeach()

  list(LENGTH requested_me_sanitizers me_count)
  if(me_count GREATER 1)
    message(FATAL_ERROR "The address, memory, and thread sanitizers are mutually exclusive. "
                        "Only one may be used in a build. "
                        "Requested mutally exclusive sanitizers: ${requested_me_sanitizers}")
  endif()
endfunction()

