#-----------------------------------------------------------------------------
# Include all the necessary files for macros
#-----------------------------------------------------------------------------
include (${CMAKE_ROOT}/Modules/CheckFunctionExists.cmake)
include (${CMAKE_ROOT}/Modules/CheckIncludeFile.cmake)
include (${CMAKE_ROOT}/Modules/CheckIncludeFileCXX.cmake)
include (${CMAKE_ROOT}/Modules/CheckIncludeFiles.cmake)
include (${CMAKE_ROOT}/Modules/CheckLibraryExists.cmake)
include (${CMAKE_ROOT}/Modules/CheckSymbolExists.cmake)
include (${CMAKE_ROOT}/Modules/CheckTypeSize.cmake)
include (${CMAKE_ROOT}/Modules/CheckVariableExists.cmake)
if(CMAKE_CXX_COMPILER)
  include (${CMAKE_ROOT}/Modules/TestForSTDNamespace.cmake)
endif(CMAKE_CXX_COMPILER)

#-----------------------------------------------------------------------------
# APPLE/Darwin setup
#-----------------------------------------------------------------------------
if (APPLE)
  list (LENGTH CMAKE_OSX_ARCHITECTURES ARCH_LENGTH)
  if (ARCH_LENGTH GREATER 1)
    set (CMAKE_OSX_ARCHITECTURES "" CACHE STRING "" FORCE)
    message(FATAL_ERROR "Building Universal Binaries on OS X is NOT supported by the H5BLOSC project. This is"
    "due to technical reasons. The best approach would be build each architecture in separate directories"
    "and use the 'lipo' tool to combine them into a single executable or library. The 'CMAKE_OSX_ARCHITECTURES'"
    "variable has been set to a blank value which will build the default architecture for this system.")
  endif ()
  set (${H5BLOSC_PREFIX}_AC_APPLE_UNIVERSAL_BUILD 0)
endif (APPLE)

# Check for Darwin (not just Apple - we also want to catch OpenDarwin)
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin") 
    set (${H5BLOSC_PREFIX}_HAVE_DARWIN 1) 
endif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")

# Check for Solaris
if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS") 
    set (${H5BLOSC_PREFIX}_HAVE_SOLARIS 1) 
endif (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")

#-----------------------------------------------------------------------------
# This MACRO checks IF the symbol exists in the library and IF it
# does, it appends library to the list.
#-----------------------------------------------------------------------------
set (LINK_LIBS "")
MACRO (CHECK_LIBRARY_EXISTS_CONCAT LIBRARY SYMBOL VARIABLE)
  CHECK_LIBRARY_EXISTS ("${LIBRARY};${LINK_LIBS}" ${SYMBOL} "" ${VARIABLE})
  if (${VARIABLE})
    set (LINK_LIBS ${LINK_LIBS} ${LIBRARY})
  endif (${VARIABLE})
ENDMACRO (CHECK_LIBRARY_EXISTS_CONCAT)

# ----------------------------------------------------------------------
# WINDOWS Hard code Values
# ----------------------------------------------------------------------

set (WINDOWS)
if (WIN32)
  if (MINGW)
    set (${H5BLOSC_PREFIX}_HAVE_MINGW 1)
    set (WINDOWS 1) # MinGW tries to imitate Windows
    set (CMAKE_REQUIRED_FLAGS "-DWIN32_LEAN_AND_MEAN=1 -DNOGDI=1")
  endif (MINGW)
  set (${H5BLOSC_PREFIX}_HAVE_WIN32_API 1)
  set (CMAKE_REQUIRED_LIBRARIES "ws2_32.lib;wsock32.lib")
  if (NOT UNIX AND NOT MINGW)
    set (WINDOWS 1)
    set (CMAKE_REQUIRED_FLAGS "/DWIN32_LEAN_AND_MEAN=1 /DNOGDI=1")
    if (MSVC)
      set (${H5BLOSC_PREFIX}_HAVE_VISUAL_STUDIO 1)
    endif (MSVC)
  endif (NOT UNIX AND NOT MINGW)
endif (WIN32)

if (WINDOWS)
  set (${H5BLOSC_PREFIX}_HAVE_STDDEF_H 1)
  set (${H5BLOSC_PREFIX}_HAVE_SYS_STAT_H 1)
  set (${H5BLOSC_PREFIX}_HAVE_SYS_TYPES_H 1)
  set (${H5BLOSC_PREFIX}_HAVE_LIBM 1)
  set (${H5BLOSC_PREFIX}_HAVE_STRDUP 1)
  set (${H5BLOSC_PREFIX}_HAVE_SYSTEM 1)
  set (${H5BLOSC_PREFIX}_HAVE_LONGJMP 1)
  if (NOT MINGW)
    set (${H5BLOSC_PREFIX}_HAVE_GETHOSTNAME 1)
  endif (NOT MINGW)
  set (${H5BLOSC_PREFIX}_HAVE_FUNCTION 1)
  set (${H5BLOSC_PREFIX}_GETTIMEOFDAY_GIVES_TZ 1)
  set (${H5BLOSC_PREFIX}_HAVE_TIMEZONE 1)
  set (${H5BLOSC_PREFIX}_HAVE_GETTIMEOFDAY 1)
  if (MINGW)
    set (${H5BLOSC_PREFIX}_HAVE_WINSOCK2_H 1)
  endif (MINGW)
  set (${H5BLOSC_PREFIX}_HAVE_LIBWS2_32 1)
  set (${H5BLOSC_PREFIX}_HAVE_LIBWSOCK32 1)
endif (WINDOWS)

# ----------------------------------------------------------------------
# END of WINDOWS Hard code Values
# ----------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  Check for the math library "m"
#-----------------------------------------------------------------------------
if (NOT WINDOWS)
  CHECK_LIBRARY_EXISTS_CONCAT ("m" ceil     ${H5BLOSC_PREFIX}_HAVE_LIBM)
  CHECK_LIBRARY_EXISTS_CONCAT ("ws2_32" WSAStartup  ${H5BLOSC_PREFIX}_HAVE_LIBWS2_32)
  CHECK_LIBRARY_EXISTS_CONCAT ("wsock32" gethostbyname ${H5BLOSC_PREFIX}_HAVE_LIBWSOCK32)
endif (NOT WINDOWS)

# UCB (BSD) compatibility library
CHECK_LIBRARY_EXISTS_CONCAT ("ucb"    gethostname  ${HDF_PREFIX}_HAVE_LIBUCB)

# For other tests to use the same libraries
set (CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${LINK_LIBS})

set (USE_INCLUDES "")
if (WINDOWS)
  set (USE_INCLUDES ${USE_INCLUDES} "windows.h")
endif (WINDOWS)

# For other other specific tests, use this MACRO.
MACRO (H5BLOSC_FUNCTION_TEST OTHER_TEST)
  if ("${H5BLOSC_PREFIX}_${OTHER_TEST}" MATCHES "^${H5BLOSC_PREFIX}_${OTHER_TEST}$")
    set (MACRO_CHECK_FUNCTION_DEFINITIONS "-D${OTHER_TEST} ${CMAKE_REQUIRED_FLAGS}")
    set (OTHER_TEST_ADD_LIBRARIES)
    if (CMAKE_REQUIRED_LIBRARIES)
      set (OTHER_TEST_ADD_LIBRARIES "-DLINK_LIBRARIES:STRING=${CMAKE_REQUIRED_LIBRARIES}")
    endif (CMAKE_REQUIRED_LIBRARIES)

    foreach (def ${H5BLOSC_EXTRA_TEST_DEFINITIONS})
      set (MACRO_CHECK_FUNCTION_DEFINITIONS "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D${def}=${${def}}")
    endforeach (def)

    foreach (def
        HAVE_SYS_TIME_H
        HAVE_UNISTD_H
        HAVE_SYS_TYPES_H
        HAVE_SYS_SOCKET_H
    )
      if ("${${H5BLOSC_PREFIX}_${def}}")
        set (MACRO_CHECK_FUNCTION_DEFINITIONS "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D${def}")
      endif ("${${H5BLOSC_PREFIX}_${def}}")
    endforeach (def)

    if (LARGEFILE)
      set (MACRO_CHECK_FUNCTION_DEFINITIONS
          "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE"
      )
    endif (LARGEFILE)

    #message (STATUS "Performing ${OTHER_TEST}")
    try_compile (${OTHER_TEST}
        ${CMAKE_BINARY_DIR}
        ${H5BLOSC_RESOURCES_DIR}/H5BLOSCTests.c
        CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=${MACRO_CHECK_FUNCTION_DEFINITIONS}
        "${OTHER_TEST_ADD_LIBRARIES}"
        OUTPUT_VARIABLE OUTPUT
    )
    if (${OTHER_TEST})
      set (${H5BLOSC_PREFIX}_${OTHER_TEST} 1 CACHE INTERNAL "Other test ${FUNCTION}")
      message (STATUS "Performing Other Test ${OTHER_TEST} - Success")
    else (${OTHER_TEST})
      message (STATUS "Performing Other Test ${OTHER_TEST} - Failed")
      set (${H5BLOSC_PREFIX}_${OTHER_TEST} "" CACHE INTERNAL "Other test ${FUNCTION}")
      file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
          "Performing Other Test ${OTHER_TEST} failed with the following output:\n"
          "${OUTPUT}\n"
      )
    endif (${OTHER_TEST})
  endif ("${H5BLOSC_PREFIX}_${OTHER_TEST}" MATCHES "^${H5BLOSC_PREFIX}_${OTHER_TEST}$")
ENDMACRO (H5BLOSC_FUNCTION_TEST)

H5BLOSC_FUNCTION_TEST (STDC_HEADERS)

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Check IF header file exists and add it to the list.
#-----------------------------------------------------------------------------
MACRO (CHECK_INCLUDE_FILE_CONCAT FILE VARIABLE)
  CHECK_INCLUDE_FILES ("${USE_INCLUDES};${FILE}" ${VARIABLE})
  if (${VARIABLE})
    set (USE_INCLUDES ${USE_INCLUDES} ${FILE})
  endif (${VARIABLE})
ENDMACRO (CHECK_INCLUDE_FILE_CONCAT)

#-----------------------------------------------------------------------------
#  Check for the existence of certain header files
#-----------------------------------------------------------------------------
CHECK_INCLUDE_FILE_CONCAT ("unistd.h"        ${H5BLOSC_PREFIX}_HAVE_UNISTD_H)
CHECK_INCLUDE_FILE_CONCAT ("sys/stat.h"      ${H5BLOSC_PREFIX}_HAVE_SYS_STAT_H)
CHECK_INCLUDE_FILE_CONCAT ("sys/types.h"     ${H5BLOSC_PREFIX}_HAVE_SYS_TYPES_H)
CHECK_INCLUDE_FILE_CONCAT ("stddef.h"        ${H5BLOSC_PREFIX}_HAVE_STDDEF_H)
CHECK_INCLUDE_FILE_CONCAT ("stdint.h"        ${H5BLOSC_PREFIX}_HAVE_STDINT_H)

# IF the c compiler found stdint, check the C++ as well. On some systems this
# file will be found by C but not C++, only do this test IF the C++ compiler
# has been initialized (e.g. the project also includes some c++)
if (${H5BLOSC_PREFIX}_HAVE_STDINT_H AND CMAKE_CXX_COMPILER_LOADED)
  CHECK_INCLUDE_FILE_CXX ("stdint.h" ${H5BLOSC_PREFIX}_HAVE_STDINT_H_CXX)
  if (NOT ${H5BLOSC_PREFIX}_HAVE_STDINT_H_CXX)
    set (${H5BLOSC_PREFIX}_HAVE_STDINT_H "" CACHE INTERNAL "Have includes HAVE_STDINT_H")
    set (USE_INCLUDES ${USE_INCLUDES} "stdint.h")
  endif (NOT ${H5BLOSC_PREFIX}_HAVE_STDINT_H_CXX)
endif (${H5BLOSC_PREFIX}_HAVE_STDINT_H AND CMAKE_CXX_COMPILER_LOADED)

# Windows
CHECK_INCLUDE_FILE_CONCAT ("io.h"            ${H5BLOSC_PREFIX}_HAVE_IO_H)
if (NOT CYGWIN)
  CHECK_INCLUDE_FILE_CONCAT ("winsock2.h"      ${H5BLOSC_PREFIX}_HAVE_WINSOCK_H)
endif (NOT CYGWIN)

CHECK_INCLUDE_FILE_CONCAT ("pthread.h"       ${H5BLOSC_PREFIX}_HAVE_PTHREAD_H)
CHECK_INCLUDE_FILE_CONCAT ("string.h"        ${H5BLOSC_PREFIX}_HAVE_STRING_H)
CHECK_INCLUDE_FILE_CONCAT ("strings.h"       ${H5BLOSC_PREFIX}_HAVE_STRINGS_H)
CHECK_INCLUDE_FILE_CONCAT ("time.h"          ${H5BLOSC_PREFIX}_HAVE_TIME_H)
CHECK_INCLUDE_FILE_CONCAT ("stdlib.h"        ${H5BLOSC_PREFIX}_HAVE_STDLIB_H)
CHECK_INCLUDE_FILE_CONCAT ("memory.h"        ${H5BLOSC_PREFIX}_HAVE_MEMORY_H)
CHECK_INCLUDE_FILE_CONCAT ("dlfcn.h"         ${H5BLOSC_PREFIX}_HAVE_DLFCN_H)
CHECK_INCLUDE_FILE_CONCAT ("fcntl.h"         ${H5BLOSC_PREFIX}_HAVE_FCNTL_H)
CHECK_INCLUDE_FILE_CONCAT ("inttypes.h"      ${H5BLOSC_PREFIX}_HAVE_INTTYPES_H)

#-----------------------------------------------------------------------------
#  Check for large file support
#-----------------------------------------------------------------------------

# The linux-lfs option is deprecated.
set (LINUX_LFS 0)

set (H5BLOSC_EXTRA_C_FLAGS)
set (H5BLOSC_EXTRA_FLAGS)
if (NOT WINDOWS)
  if (NOT ${H5BLOSC_PREFIX}_HAVE_SOLARIS)
  # Linux Specific flags
  # This was originally defined as _POSIX_SOURCE which was updated to
  # _POSIX_C_SOURCE=199506L to expose a greater amount of POSIX
  # functionality so clock_gettime and CLOCK_MONOTONIC are defined
  # correctly.
  # POSIX feature information can be found in the gcc manual at:
  # http://www.gnu.org/s/libc/manual/html_node/Feature-Test-Macros.html
  set (H5BLOSC_EXTRA_C_FLAGS -D_POSIX_C_SOURCE=199506L)
  # _BSD_SOURCE deprecated in GLIBC >= 2.20
  try_run (HAVE_DEFAULT_SOURCE_RUN HAVE_DEFAULT_SOURCE_COMPILE
        ${CMAKE_BINARY_DIR}
        ${H5BLOSC_RESOURCES_DIR}/H5BLOSCTests.c
        CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=-DHAVE_DEFAULT_SOURCE
        OUTPUT_VARIABLE OUTPUT
    )
  if (HAVE_DEFAULT_SOURCE_COMPILE AND HAVE_DEFAULT_SOURCE_RUN)
    set (H5BLOSC_EXTRA_FLAGS -D_DEFAULT_SOURCE)
  else (HAVE_DEFAULT_SOURCE_COMPILE AND HAVE_DEFAULT_SOURCE_RUN)
    set (H5BLOSC_EXTRA_FLAGS -D_BSD_SOURCE)
  endif (HAVE_DEFAULT_SOURCE_COMPILE AND HAVE_DEFAULT_SOURCE_RUN)

  option (H5BLOSC_ENABLE_LARGE_FILE "Enable support for large (64-bit) files on Linux." ON)
  if (H5BLOSC_ENABLE_LARGE_FILE)
    set (msg "Performing TEST_LFS_WORKS")
    try_run (TEST_LFS_WORKS_RUN   TEST_LFS_WORKS_COMPILE
        ${CMAKE_BINARY_DIR}
        ${H5BLOSC_RESOURCES_DIR}/H5BLOSCTests.c
        CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=-DTEST_LFS_WORKS
        OUTPUT_VARIABLE OUTPUT
    )
    if (TEST_LFS_WORKS_COMPILE)
      if (TEST_LFS_WORKS_RUN  MATCHES 0)
        set (TEST_LFS_WORKS 1 CACHE INTERNAL ${msg})
        set (LARGEFILE 1)
        set (H5BLOSC_EXTRA_FLAGS ${H5BLOSC_EXTRA_FLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE)
        message (STATUS "${msg}... yes")
      else (TEST_LFS_WORKS_RUN  MATCHES 0)
        set (TEST_LFS_WORKS "" CACHE INTERNAL ${msg})
        message (STATUS "${msg}... no")
        file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
              "Test TEST_LFS_WORKS Run failed with the following output and exit code:\n ${OUTPUT}\n"
        )
      endif (TEST_LFS_WORKS_RUN  MATCHES 0)
    else (TEST_LFS_WORKS_COMPILE )
      set (TEST_LFS_WORKS "" CACHE INTERNAL ${msg})
      message (STATUS "${msg}... no")
      file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
          "Test TEST_LFS_WORKS Compile failed with the following output:\n ${OUTPUT}\n"
      )
    endif (TEST_LFS_WORKS_COMPILE)
  endif (H5BLOSC_ENABLE_LARGE_FILE)
  set (CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS} ${HDF_EXTRA_FLAGS})
  endif (NOT ${H5BLOSC_PREFIX}_HAVE_SOLARIS)
endif (NOT WINDOWS)

add_definitions (${H5BLOSC_EXTRA_FLAGS})
#-----------------------------------------------------------------------------
# Check for some functions that are used
#
if (NOT WINDOWS)
  foreach (test
      HAVE_ATTRIBUTE
      HAVE_C99_FUNC
      HAVE_FUNCTION
      HAVE_C99_DESIGNATED_INITIALIZER
      SYSTEM_SCOPE_THREADS
      CXX_HAVE_OFFSETOF
  )
    H5BLOSC_FUNCTION_TEST (${test})
  endforeach (test)
endif (NOT WINDOWS)

