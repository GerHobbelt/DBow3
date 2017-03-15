INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR}/src)
LINK_LIBRARIES(${PROJECT_NAME})

# https://github.com/ruslo/hunter/wiki/pkg.gtest
if(WITH_HUNTER_GTESTS)
  hunter_add_package(GTest) 
  find_package(GTest CONFIG REQUIRED)
endif(WITH_HUNTER_GTESTS)

ADD_EXECUTABLE(test_iobinary test_iobinary.cpp  )
ADD_EXECUTABLE(test_bigvoc test_bigvoc.cpp  )
ADD_EXECUTABLE(test_flann test_flann.cpp  )
ADD_EXECUTABLE(test_fbow test_fbow.cpp  )
