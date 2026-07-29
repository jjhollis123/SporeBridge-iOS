cmake_minimum_required(VERSION 3.24)

project(SporeBridge VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(spore_install_validator STATIC
  src/spore_install_validator.cpp
)
target_include_directories(spore_install_validator PUBLIC src)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
  enable_language(OBJCXX)

  add_executable(SporeBridge MACOSX_BUNDLE
    ios/main.mm
    ios/SporeImportViewController.mm
  )

  target_link_libraries(SporeBridge PRIVATE
    spore_install_validator
    "-framework Foundation"
    "-framework UIKit"
    "-framework UniformTypeIdentifiers"
  )

  set_target_properties(SporeBridge PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist.in"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "uk.co.jjhollis.sporebridge"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
  )
else()
  enable_testing()

  add_executable(spore_install_validator_tests
    tests/spore_install_validator_tests.cpp
  )
  target_link_libraries(spore_install_validator_tests PRIVATE
    spore_install_validator
  )
  add_test(
    NAME spore_install_validator_tests
    COMMAND spore_install_validator_tests
  )
endif()

