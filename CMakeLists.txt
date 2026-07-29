cmake_minimum_required(VERSION 3.24)

project(SporeBridge VERSION 0.3.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(spore_install_validator STATIC
  src/spore_install_validator.cpp
)
target_include_directories(spore_install_validator PUBLIC src)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
  enable_language(OBJC)
  enable_language(OBJCXX)

  set(BOXEDWINE_SOURCE_DIR "" CACHE PATH
      "Path to the pinned Boxedwine source checkout")
  set(BOXEDWINE_BOOTSTRAP_ROOT_ZIP "" CACHE FILEPATH
      "Path to the generated minimal x86 bootstrap root")

  if(NOT EXISTS "${BOXEDWINE_SOURCE_DIR}/source/sdl/main.cpp")
    message(FATAL_ERROR
      "BOXEDWINE_SOURCE_DIR must point to the prepared Boxedwine checkout")
  endif()
  if(NOT EXISTS "${BOXEDWINE_BOOTSTRAP_ROOT_ZIP}")
    message(FATAL_ERROR
      "BOXEDWINE_BOOTSTRAP_ROOT_ZIP must point to the generated root ZIP")
  endif()

  add_subdirectory(runtime/boxedwine)

  set_source_files_properties(
    "${BOXEDWINE_BOOTSTRAP_ROOT_ZIP}"
    PROPERTIES MACOSX_PACKAGE_LOCATION Resources
  )
  set_source_files_properties(
    "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt"
    "${CMAKE_CURRENT_SOURCE_DIR}/THIRD_PARTY_NOTICES.md"
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/Licences/SporeBridge"
  )
  set_source_files_properties(
    "${BOXEDWINE_SOURCE_DIR}/license.txt"
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/Licences/Boxedwine"
  )
  set_source_files_properties(
    "${BOXEDWINE_SOURCE_DIR}/lib/sdl2/COPYING.txt"
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/Licences/SDL2"
  )
  set_source_files_properties(
    "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/COPYING.txt"
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/Licences/SoftFloat"
  )

  add_executable(SporeBridge MACOSX_BUNDLE
    "${BOXEDWINE_BOOTSTRAP_ROOT_ZIP}"
    "${BOXEDWINE_SOURCE_DIR}/lib/sdl2/COPYING.txt"
    "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/COPYING.txt"
    "${BOXEDWINE_SOURCE_DIR}/license.txt"
    LICENSE.txt
    THIRD_PARTY_NOTICES.md
    ios/BoxedwineBootstrap.mm
    ios/main.mm
    ios/RuntimeReadinessProbe.mm
    ios/SporeImportViewController.mm
  )

  target_link_libraries(SporeBridge PRIVATE
    boxedwine_runtime
    spore_install_validator
    "-framework Foundation"
    "-framework Metal"
    "-framework UIKit"
    "-framework UniformTypeIdentifiers"
  )

  set_target_properties(SporeBridge PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist.in"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
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
