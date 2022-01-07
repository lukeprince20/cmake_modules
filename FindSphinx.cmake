#[=======================================================================[.rst:
FindSphinx
----------

Sphinx is a documentation generation tool (see http://www.sphinx-doc.org).
This module looks for the ``sphinx-build`` tool.

The following variables are defined by this module:

.. variable:: SPHINX_FOUND

  True if the ``sphinx-build`` executable was found.

.. variable:: SPHINX_VERSION

  The version reported by ``sphinx-build --version``.

  The module defines ``IMPORTED`` targets for Sphinx and each component found.
  These can be used as part of custom commands, etc. and should be preferred over
  old-style (and now deprecated) variables like ``SPHINX_EXECUTABLE``. The
  following import target is defined if the corresponding executable is found:

::

  Sphinx::sphinx


Functions
^^^^^^^^^

.. command:: sphinx_add_docs

  This function is intended as a convenience for adding a target for generating
  documentation with Sphinx using it's various builders.

  ::

    sphinx_add_docs(targetName builderName
        [SOURCEDIR dir]
        [OUTPUTDIR dir]
        [FILENAMES files...])

  The function defines a custom target that runs ``sphinx-build``.
  Documentation is generated from the files in SOURCEDIR and placed in the
  OUTPUTDIR. By default, everything that is outdated is build. Output only for
  selected files can be built by specifying individual FILENAMES.
  
  So that relative input paths work as expected, by default the source
  directory of the Sphinx command will be the current source directory (i.e.
  :variable:`CMAKE_CURRENT_SOURCE_DIR`). The output directory will be the
  current build directory (i.e. :variable:`CMAKE_CURRENT_BINARY_DIR`). Any
  filenames passed to Sphinx will be assumed relative to the current source
  directory.

Example usage:

  .. code-block:: cmake

    sphinx_add_docs(sphinx-html html
        SOURCEDIR "src"
        OUTPUTDIR "sphinx-build"
    )

Deprecated Result Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^

For compatibility with previous versions of CMake, the following variables
are also defined but they are deprecated and should no longer be used:

.. variable:: SPHINX_EXECUTABLE

  The path to the ``sphinx-build`` command. If projects need to refer to the
  ``sphinx-build`` executable directly, they should use the ``Sphinx::sphinx``
  import target instead.


#]=======================================================================]

set(_sphinx_hints)
set(_sphinx_paths)

find_package(Python QUIET)
if(Python_EXECUTABLE)
    get_filename_component(_python_dir "${Python_EXECUTABLE}" DIRECTORY)
    list(APPEND _sphinx_hints 
        "${_python_dir}"
        "${_python_dir}/bin"
        "${_python_dir}/Scripts"
    )
    list(APPEND _sphinx_paths
        /usr/share/sphinx/scripts/python${Python_VERSION_MAJOR}
    )
endif()

list(APPEND _sphinx_paths
    /usr/bin
    /usr/local/bin
    /opt/local/bin
)

find_program(SPHINX_EXECUTABLE
    NAMES sphinx-build sphinx-build.exe sphinx-build-3
    HINTS ${_sphinx_hints}
    PATHS ${_sphinx_paths}
    DOC "Sphinx documentation generation tool (http://www.sphinx-doc.org)"
)
mark_as_advanced(SPHINX_EXECUTABLE)

if(SPHINX_EXECUTABLE)
    # determine sphinx-build version
    execute_process(COMMAND "${SPHINX_EXECUTABLE}" --version
        OUTPUT_VARIABLE SPHINX_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _Sphinx_version_result
    )
    if(_Sphinx_version_result)
        message(WARNING "Unable to determine sphinx-build version: ${_Sphinx_version_result}")
    endif()

    # Parse version output
    if(SPHINX_VERSION MATCHES "^sphinx-build ([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(SPHINX_VERSION_MAJOR "${CMAKE_MATCH_1}")
        set(SPHINX_VERSION_MINOR "${CMAKE_MATCH_2}")
        set(SPHINX_VERSION_PATCH "${CMAKE_MATCH_3}")
        set(SPHINX_VERSION "${SPHINX_VERSION_MAJOR}.${SPHINX_VERSION_MINOR}.${SPHINX_VERSION_PATCH}")
    endif()

    # Create an imported target for Sphinx
    if(NOT TARGET Sphinx::sphinx)
        add_executable(Sphinx::sphinx IMPORTED GLOBAL)
        set_target_properties(Sphinx::sphinx PROPERTIES IMPORTED_LOCATION "${SPHINX_EXECUTABLE}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Sphinx
    REQUIRED_VARS SPHINX_EXECUTABLE
    VERSION_VAR SPHINX_VERSION
)


function(sphinx_add_docs target builder)
    # Lowercase for consistency with builder/folder names
    string(TOLOWER ${builder} builder)

    # Parse arguments
    cmake_parse_arguments(SPHINX "" "SOURCEDIR;OUTPUTDIR" "FILENAMES" ${ARGN})
    
    # Convert any relative path to real paths
    get_filename_component(SPHINX_SOURCEDIR "${SPHINX_SOURCEDIR}" REALPATH)
    get_filename_component(SPHINX_OUTPUTDIR "${SPHINX_OUTPUTDIR}" REALPATH BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")

    # Convert any relative paths to real paths
    if(SPHINX_FILENAMES)
        set(realpath_filenames)
        foreach(filename ${SPHINX_FILENAMES})
            get_filename_component(filename "${filename}" REALPATH)
            list(APPEND realpath_filenames "${filename}")
        endforeach()
        set(SPHINX_FILENAMES "${realpath_filenames}")
        unset(realpath_filenames)
    endif()

    # Add custom target for invoking the sphinx-build tool with the selected builder option
    # Call syntax: sphinx-build [options] <sourcedir> <outputdir> [filenames ...]
    add_custom_target(sphinx-${builder}
        COMMAND Sphinx::sphinx
            -M ${builder} # options
            "${SPHINX_SOURCEDIR}" # sourcedir
            "${SPHINX_OUTPUTDIR}" # outputdir
            ${SPHINX_FILENAMES} # filenames
        COMMENT "Generating Sphinx documentation for '${builder}' builder into '${SPHINX_OUTPUTDIR}'"
    )

    # When "clean" target is run, remove the Sphinx output directory
    if(CMAKE_VERSION VERSION_GREATER 3.14)
        # Note: this property only works for the Ninja and the Makefile generators.
        set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${SPHINX_OUTPUTDIR}")
    else()
        # Note: this property only works for the Makefile generator.
        set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${SPHINX_OUTPUTDIR}")
    endif()
endfunction()
