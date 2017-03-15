
INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR}/src )
LINK_LIBRARIES(${PROJECT_NAME})

if(OPENCV_VERSION_3)

  ADD_EXECUTABLE(demo_general demo_general.cpp)
  ADD_EXECUTABLE(create_voc_step0 create_voc_step0.cpp)
  ADD_EXECUTABLE(create_voc_step1 create_voc_step1.cpp)
  #INSTALL(TARGETS demo_general  create_voc_step0  create_voc_step1  RUNTIME DESTINATION bin)
  if(NOT IOS)

    install(
        TARGETS demo_general create_voc_step0 create_voc_step1
        EXPORT "${TARGETS_EXPORT_NAME}"
        LIBRARY DESTINATION "lib"
        ARCHIVE DESTINATION "lib"
        RUNTIME DESTINATION "bin"
        INCLUDES DESTINATION "include"
    )

  endif()

endif()
