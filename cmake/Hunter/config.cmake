
  # Copyright (c) 2017, Luc Michalski
  # All rights reserved.
  
  if(ANDROID)
    message("ANDROID =====================================================================")

    # ---[ OpenCV
    include(SetOpenCVCMakeArgs-android) 
    set_opencv_cmake_args_android()

  elseif(IOS)
    message("IOS ======================================================================")

    # ---[ OpenCV
    include(SetOpenCVCMakeArgs-iOS) 
    set_opencv_cmake_args_ios()

  elseif(APPLE) 
    message("APPLE =======================================================================")

    # ---[ OpenCV
    include(SetOpenCVCMakeArgs-osx)
    set_opencv_cmake_args_osx()

  elseif(is_linux)
    message("is_linux ====================================================================")

    # ---[ OpenCV
    # set(OPENCV_CMAKE_ARGS BUILD_SHARED_LIBS=OFF WITH_FFMPEG=OFF WITH_IPP=OFF) #TBD
    include(SetOpenCVCMakeArgs-nix)
    set_opencv_cmake_args_nix()

  elseif(MSCV)
    message("MSVC ========================================================================")

    # ---[ OpenCV
    # set(OPENCV_CMAKE_ARGS BUILD_SHARED_LIBS=OFF WITH_FFMPEG=OFF WITH_IPP=OFF) #TBD
    include(SetOpenCVCMakeArgs-windows)
    set_opencv_cmake_args_windows()

  endif()

  list(APPEND OPENCV_CMAKE_ARGS 
    BUILD_opencv_world=OFF 
    BUILD_EIGEN=OFF
  )

  if(USE_CONTRIB)
    list(APPEND OPENCV_CMAKE_ARGS OPENCV_WITH_EXTRA_MODULES=YES)
  endif(USE_CONTRIB)

  #CMAKE_CXX_FLAGS=-Wno-c++11-narrowing

  # ---[ print out - OpenCV - user-defined CMake arguments
  foreach(OPENCV_CMAKE_ARG ${OPENCV_CMAKE_ARGS})
    message(STATUS " - OPENCV_CMAKE_ARG: ${OPENCV_CMAKE_ARG}")
  endforeach()

  # ---[ print out - CMake arguments
  # get_cmake_property(_variableNames VARIABLES)
  # foreach (_variableName ${_variableNames})
  #     message(STATUS "VARIABLE: ${_variableName}=${${_variableName}}")
  # endforeach()
  # return()

  hunter_config(OpenCV VERSION ${HUNTER_OpenCV_VERSION} CMAKE_ARGS "${OPENCV_CMAKE_ARGS}")




