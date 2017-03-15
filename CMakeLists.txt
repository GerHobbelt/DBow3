# Added by Luc Michalski - 2017

cmake_minimum_required(VERSION 3.5)

string(COMPARE NOTEQUAL "$ENV{TRAVIS_TAG}" "" travis_deploy)
string(COMPARE EQUAL "$ENV{APPVEYOR_REPO_TAG}" "true" appveyor_deploy)

if(travis_deploy)
  set(version "$ENV{TRAVIS_TAG}")
elseif(appveyor_deploy)
  set(version "$ENV{APPVEYOR_REPO_TAG_NAME}")
else()
  set(version "v0.0.1")
endif()

string(REGEX REPLACE "^v" "" version "${version}")

#-----------------------------------------------------------------------------
# Project - Context Variables
#-----------------------------------------------------------------------------

set(current_project_name            "DBow3")
set(current_dir                     "${CMAKE_CURRENT_SOURCE_DIR}")
set(current_project_root_dir        "${current_dir}")

#-----------------------------------------------------------------------------
# Project - Setup
#-----------------------------------------------------------------------------

# build
OPTION(BUILD_SHARED_LIBS            "Set to OFF to build static libraries"      ON)

# components
OPTION(USE_CONTRIB                  "Set to ON if contrib are installed"        ON)
OPTION(BUILD_UTILS                  "Set to OFF to not build utils"             ON)

# docs
OPTION(INSTALL_DOC                  "Set to ON to build/install Documentation"  OFF)

# hunter
OPTION(WITH_HUNTER_CUSTOM_CONFIG    "Load hunter custom configuration"          OFF)
OPTION(WITH_HUNTER_GTESTS           "Build Google Test package with hunter"     OFF)
#OPTION(HUNTER_USE_CACHE_SERVERS     "Load hunter custom configuration"          ON)
#set(HUNTER_USE_CACHE_SERVERS NO)

#-----------------------------------------------------------------------------
# CMake - Hunter Package - Custom Configurations
#-----------------------------------------------------------------------------
if(WITH_HUNTER_CUSTOM_CONFIG)
  list(APPEND CMAKE_MODULE_PATH "cmake/Settings")
endif(WITH_HUNTER_CUSTOM_CONFIG)

#-----------------------------------------------------------------------------
# CMake - Hunter Gate
#-----------------------------------------------------------------------------

include("${current_dir}/cmake/HunterGate.cmake")

if(WITH_HUNTER_CUSTOM_CONFIG) # use local config cmake/Hunter/config.cmake
  message(STATUS " [Sniper] *** Loading *** Loading hunter custom config file")
  HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.18.15.tar.gz"
    SHA1 "57991b41173c0e3c7501c7929cad8323277fab4c"
    LOCAL
  )

else()
  message(STATUS " [Sniper] *** Loading *** hunter default config")
  HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.18.15.tar.gz"
    SHA1 "57991b41173c0e3c7501c7929cad8323277fab4c"
  )

endif()

#-----------------------------------------------------------------------------
# Project - Init
#-----------------------------------------------------------------------------
project(${current_project_name} VERSION ${version} LANGUAGES C CXX)

string(REGEX MATCHALL "[0-9]" PROJECT_VERSION_PARTS "${PROJECT_VERSION}")
list(GET PROJECT_VERSION_PARTS 0 PROJECT_VERSION_MAJOR)
list(GET PROJECT_VERSION_PARTS 1 PROJECT_VERSION_MINOR)
list(GET PROJECT_VERSION_PARTS 2 PROJECT_VERSION_PATCH)
set(PROJECT_SOVERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")

#-----------------------------------------------------------------------------
# Project - Build Platform flags
#-----------------------------------------------------------------------------

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(is_android ${ANDROID}) # syntax compatibility
string(COMPARE EQUAL "${CMAKE_OSX_SYSROOT}" "iphoneos" is_ios)
string(COMPARE EQUAL "${CMAKE_SYSTEM_NAME}" "Linux" is_linux)
string(COMPARE EQUAL "${CMAKE_GENERATOR}" "Xcode" is_xcode)

# See: cmake/Hunter/config.cmake
# First call to 'hunter_add_package' will contains read of Hunter/config.cmake
# Next variables will be used:
#   * is_ios
#   * is_linux
hunter_add_package(Sugar)
include("${SUGAR_ROOT}/cmake/Sugar")
include(sugar_include)

#------------------------------------------------------
# Build type
#------------------------------------------------------

IF(NOT CMAKE_BUILD_TYPE )
  SET(CMAKE_BUILD_TYPE "Release" )
ENDIF()

#------------------------------------------------------
# Lib Names and Dirs
#------------------------------------------------------

if(WIN32)
  # Postfix of DLLs:
  SET(PROJECT_DLLVERSION "${PROJECT_VERSION_MAJOR}${PROJECT_VERSION_MINOR}${PROJECT_VERSION_PATCH}")
  SET(RUNTIME_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin CACHE PATH "Directory for dlls and binaries")
  SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin CACHE PATH "Directory for binaries")
  SET(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin CACHE PATH "Directory for dlls")
else()
  # Postfix of so's:
  set(PROJECT_DLLVERSION)
  SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_INSTALL_PREFIX}/lib/cmake/ /usr/lib/cmake )
endif()

# ----------------------------------------------------------------------------
#   Find Dependencies
# ----------------------------------------------------------------------------

# ---[ OpenCV
hunter_add_package(OpenCV)
find_package(OpenCV REQUIRED)
if(OpenCV_VERSION MATCHES "^2\\.")
  find_package(OpenCV REQUIRED COMPONENTS core highgui imgproc contrib)
else()
  find_package(OpenCV REQUIRED COMPONENTS core highgui imgproc imgcodecs xphoto xfeatures2d) # objdetect xphoto
endif()
message(STATUS "OpenCV found (${OpenCV_CONFIG_PATH})")
IF(USE_CONTRIB)
add_definitions(-DUSE_CONTRIB)
ENDIF()
if(NOT OpenCV_VERSION VERSION_LESS "3.0")
    ADD_DEFINITIONS(-DOPENCV_VERSION_3)
    SET(OPENCV_VERSION_3 ON)
ELSE()
    SET(OPENCV_VERSION_3 OFF)
ENDIF()

include_directories(${OpenCV_INCLUDE_DIRS})

set(REQUIRED_LIBRARIES ${REQUIRED_LIBRARIES} ${OpenCV_LIBS})

# ----------------------------------------------------------------------------
#   PROJECT CONFIGURATION
#   force some variables that could be defined in the command line to be written to cache
# ----------------------------------------------------------------------------
if(INSTALL_DOC)
  FIND_PACKAGE(Doxygen REQUIRED)
  MESSAGE( STATUS "INSTALL_DOC:         ${INSTALL_DOC} ")
  INCLUDE("${PROJECT_SOURCE_DIR}/generateDoc.cmake")
  GENERATE_DOCUMENTATION(${PROJECT_SOURCE_DIR}/dox.in)
endif()
 
# ----------------------------------------------------------------------------
#   Uninstall target, for "make uninstall"
# ----------------------------------------------------------------------------
CONFIGURE_FILE( "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in" "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake" IMMEDIATE @ONLY)
ADD_CUSTOM_TARGET(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")

# ----------------------------------------------------------------------------
# create configuration file from .in file (If you use windows take care with paths)
# ----------------------------------------------------------------------------

CONFIGURE_FILE("${PROJECT_SOURCE_DIR}/config.cmake.in" "${PROJECT_BINARY_DIR}/Find${PROJECT_NAME}.cmake")
CONFIGURE_FILE("${PROJECT_SOURCE_DIR}/config.cmake.in" "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake")
INSTALL(FILES "${PROJECT_BINARY_DIR}/Find${PROJECT_NAME}.cmake" DESTINATION lib/cmake/ )

# ----------------------------------------------------------------------------
#   Program Optimization and debug (Extracted from OpenCV)
# ----------------------------------------------------------------------------
set(WARNINGS_ARE_ERRORS         OFF CACHE BOOL "Treat warnings as errors")
set(WHOLE_PROGRAM_OPTIMIZATION  OFF CACHE BOOL "Flags for whole program optimization.")

set(EXTRA_C_FLAGS "")
set(EXTRA_C_FLAGS_RELEASE "")
set(EXTRA_C_FLAGS_DEBUG "")
set(EXTRA_EXE_LINKER_FLAGS "")
set(EXTRA_EXE_LINKER_FLAGS_RELEASE "")
set(EXTRA_EXE_LINKER_FLAGS_DEBUG "")

if(CMAKE_COMPILER_IS_GNUCXX OR MINGW)

    set(ENABLE_PROFILING        OFF CACHE BOOL "Enable profiling in the GCC compiler (Add flags: -g -pg)")
    set(USE_OMIT_FRAME_POINTER  ON CACHE BOOL "Enable -fomit-frame-pointer for GCC")
    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES arm*) # We can use only -O2 because the -O3 causes gcc crash
        set(USE_O2 ON CACHE BOOL "Enable -O2 for GCC")
        set(USE_FAST_MATH OFF CACHE BOOL "Enable -ffast-math for GCC")
    endif()

    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES powerpc*)
        set(USE_O3 ON CACHE BOOL "Enable -O3 for GCC")
        set(USE_POWERPC ON CACHE BOOL "Enable PowerPC for GCC")
    endif ()

    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES amd64* OR ${CMAKE_SYSTEM_PROCESSOR} MATCHES x86_64*)
        set(USE_O3 ON CACHE BOOL "Enable -O3 for GCC")
        set(USE_FAST_MATH OFF CACHE BOOL "Enable -ffast-math for GCC")
        set(USE_MMX ON CACHE BOOL "Enable MMX for GCC")
        set(USE_SSE ON CACHE BOOL "Enable SSE for GCC")
        set(USE_SSE2 ON CACHE BOOL "Enable SSE2 for GCC")
        set(USE_SSE3 ON CACHE BOOL "Enable SSE3 for GCC")
    endif()

    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES i686* OR ${CMAKE_SYSTEM_PROCESSOR} MATCHES x86)
        set(USE_O3 ON CACHE BOOL "Enable -O3 for GCC")
        set(USE_FAST_MATH OFF CACHE BOOL "Enable -ffast-math for GCC")
        set(USE_MMX ON CACHE BOOL "Enable MMX for GCC")
        set(USE_SSE OFF CACHE BOOL "Enable SSE for GCC")
        set(USE_SSE2 OFF CACHE BOOL "Enable SSE2 for GCC")
        set(USE_SSE3 OFF CACHE BOOL "Enable SSE3 for GCC")
    endif ()

    set(EXTRA_C_FLAGS "${EXTRA_C_FLAGS} -Wall")

    if(WARNINGS_ARE_ERRORS)
        set(EXTRA_C_FLAGS "${EXTRA_C_FLAGS} -Werror")
    endif()

    # The -Wno-long-long is required in 64bit systems when including sytem headers.
    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES x86_64* OR ${CMAKE_SYSTEM_PROCESSOR} MATCHES amd64*)
                set(EXTRA_C_FLAGS "${EXTRA_C_FLAGS} -Wno-long-long")
    endif()

    # Whole program optimization
    if(WHOLE_PROGRAM_OPTIMIZATION)
        set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -fwhole-program --combine")
    endif()

    # Other optimizations
    if(USE_OMIT_FRAME_POINTER)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -fomit-frame-pointer")
    endif()
    if(USE_O2)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -O2")
    endif()
    if(USE_O3)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -O3")
    endif()
    if(USE_FAST_MATH)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -ffast-math")
    endif()
    if(USE_POWERPC)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -mcpu=G3 -mtune=G5")
    endif()
    if(USE_MMX)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -mmmx")
    endif()
    if(USE_SSE)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -msse")
    endif()
    if(USE_SSE2)
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -msse2")
    endif()
    if(USE_SSE3 AND NOT MINGW) # SSE3 should be disabled under MingW because it generates compiler errors
       set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -msse3")
    endif()

    if(ENABLE_PROFILING)
        set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -pg -g")
    else()
        if(NOT APPLE)
            set(EXTRA_C_FLAGS "${EXTRA_C_FLAGS} -ffunction-sections")
        endif()
    endif()

    set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} -DNDEBUG   ")
    set(EXTRA_C_FLAGS_DEBUG "-g3 -O0 -DDEBUG -D_DEBUG -W -Wextra -Wno-return-type   ")

    MESSAGE( STATUS "-------------------------------------------------------------------------------" )
    message( STATUS "GNU COMPILER")
    MESSAGE( STATUS "-------------------------------------------------------------------------------" )

ELSE()  # MSVC


ENDIF() #END OF COMPILER SPECIFIC OPTIONS

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} ${EXTRA_C_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS}  ${EXTRA_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -std=c++11")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -std=c++11")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE} ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS_DEBUG}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${EXTRA_EXE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${EXTRA_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} ${EXTRA_EXE_LINKER_FLAGS_DEBUG}")

#------------------------------------------------
# DIRS
#------------------------------------------------
add_subdirectory(src)

IF(BUILD_UTILS)
  add_subdirectory(utils)
ENDIF()

if(BUILD_TESTS)
  if(ANDROID OR IOS)
    # TODO: Testing on simulators (devices?)
  else()
    enable_testing() # Should be in top-level CMakeLists.txt
  endif()
  add_subdirectory(tests)
endif()

### Installation (https://github.com/forexample/package-example) {

set(config_install_dir "lib/cmake/${PROJECT_NAME}")
set(include_install_dir "include")
set(generated_dir "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(version_config "${generated_dir}/${PROJECT_NAME}ConfigVersion.cmake")
set(project_config "${generated_dir}/${PROJECT_NAME}Config.cmake")
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(namespace "${PROJECT_NAME}::")

include(CMakePackageConfigHelpers)

# Note: PROJECT_VERSION is used as a VERSION
write_basic_package_version_file(
    "${version_config}" COMPATIBILITY SameMajorVersion
)

# Use variables:
#   * TARGETS_EXPORT_NAME
#   * PROJECT_NAME
configure_package_config_file(
    "cmake/Config.cmake.in"
    "${project_config}"
    INSTALL_DESTINATION "${config_install_dir}"
)

install(
    FILES "${project_config}" "${version_config}"
    DESTINATION "${config_install_dir}"
)

install(
    EXPORT "${TARGETS_EXPORT_NAME}"
    NAMESPACE "${namespace}"
    DESTINATION "${config_install_dir}"
)

# ----------------------------------------------------------------------------
# display status message for important variables
# ----------------------------------------------------------------------------
message( STATUS )
MESSAGE( STATUS "-------------------------------------------------------------------------------" )
message( STATUS "General configuration for ${PROJECT_NAME} ${PROJECT_VERSION}")
MESSAGE( STATUS "-------------------------------------------------------------------------------" )
message("    Built as dynamic libs?:" ${BUILD_SHARED_LIBS})
message("    Compiler:"                   "${CMAKE_COMPILER}"   "${CMAKE_CXX_COMPILER}")

message( STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message( STATUS "C++ flags (Release):       ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}")
message( STATUS "C++ flags (Debug):         ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG}")
message( STATUS "C++ flags (Relase+Debug):         ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

message( STATUS "CMAKE_CXX_FLAGS:         ${CMAKE_CXX_FLAGS}")
message( STATUS "CMAKE_BINARY_DIR:         ${CMAKE_BINARY_DIR}")

MESSAGE( STATUS )
MESSAGE( STATUS "CMAKE_SYSTEM_PROCESSOR = ${CMAKE_SYSTEM_PROCESSOR}" )
MESSAGE( STATUS "CMAKE_INSTALL_PREFIX = ${CMAKE_INSTALL_PREFIX}" )
MESSAGE( STATUS "CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}" )
MESSAGE( STATUS "CMAKE_MODULE_PATH = ${CMAKE_MODULE_PATH}" )
MESSAGE( STATUS "BUILD_UTILS= ${BUILD_UTILS}" )
MESSAGE( STATUS "BUILD_TESTS= ${BUILD_TESTS}" )
MESSAGE( STATUS "OPENCV_DIR= ${OpenCV_DIR} VERSION=${OpenCV_VERSION}" )

MESSAGE( STATUS "USE_CONTRIB= ${USE_CONTRIB}" )

MESSAGE( STATUS )
MESSAGE( STATUS "OpenCV_LIB_DIR=${OpenCV_LIB_DIR}")
MESSAGE( STATUS "CMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}")

MESSAGE( STATUS )
MESSAGE( STATUS )
MESSAGE( STATUS "Change a value with: cmake -D<Variable>=<Value>" )
MESSAGE( STATUS )

