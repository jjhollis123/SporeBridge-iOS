set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(HIDAPI OFF CACHE BOOL "" FORCE)
set(SDL_JOYSTICK OFF CACHE BOOL "" FORCE)
set(SDL_HAPTIC OFF CACHE BOOL "" FORCE)
set(SDL_SENSOR OFF CACHE BOOL "" FORCE)
set(RENDER_METAL OFF CACHE BOOL "" FORCE)
set(VIDEO_METAL OFF CACHE BOOL "" FORCE)
set(VIDEO_VULKAN OFF CACHE BOOL "" FORCE)

add_subdirectory(
  "${BOXEDWINE_SOURCE_DIR}/lib/sdl2"
  "${CMAKE_CURRENT_BINARY_DIR}/sdl2"
  EXCLUDE_FROM_ALL
)
target_compile_options(SDL2-static PRIVATE
  -Wno-error=declaration-after-statement
)

file(GLOB BOXEDWINE_SDL_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/sdl/*.cpp"
  "${BOXEDWINE_SOURCE_DIR}/source/sdl/singleThreaded/*.cpp"
  "${BOXEDWINE_SOURCE_DIR}/platform/sdl/*.cpp"
)
file(GLOB BOXEDWINE_PLATFORM_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/platform/linux/*.cpp"
)
file(GLOB_RECURSE BOXEDWINE_EMULATION_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/emulation/*.cpp"
)
file(GLOB BOXEDWINE_IO_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/io/*.cpp"
)
file(GLOB BOXEDWINE_OPENGL_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/opengl/*.cpp"
  "${BOXEDWINE_SOURCE_DIR}/source/opengl/sdl/*.cpp"
)
file(GLOB_RECURSE BOXEDWINE_KERNEL_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/kernel/*.cpp"
)
file(GLOB BOXEDWINE_UTIL_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/util/*.cpp"
)
file(GLOB BOXEDWINE_X11_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/x11/*.cpp"
)
file(GLOB BOXEDWINE_VULKAN_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/vulkan/*.cpp"
)
file(GLOB BOXEDWINE_SOFTFLOAT_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/source/*.c"
  "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/source/8086-SSE/*.c"
)

list(FILTER BOXEDWINE_EMULATION_SOURCES EXCLUDE REGEX
  "/source/emulation/cpu/(armv8|wasm|x32)/")
list(REMOVE_ITEM BOXEDWINE_UTIL_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/source/util/networkutils.cpp")

set(BOXEDWINE_MINIZIP_SOURCES
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib/contrib/minizip/ioapi.c"
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib/contrib/minizip/mztools.c"
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib/contrib/minizip/unzip.c"
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib/contrib/minizip/zip.c"
)

add_library(boxedwine_runtime STATIC
  ${BOXEDWINE_SDL_SOURCES}
  ${BOXEDWINE_PLATFORM_SOURCES}
  ${BOXEDWINE_EMULATION_SOURCES}
  ${BOXEDWINE_IO_SOURCES}
  ${BOXEDWINE_OPENGL_SOURCES}
  ${BOXEDWINE_KERNEL_SOURCES}
  ${BOXEDWINE_UTIL_SOURCES}
  ${BOXEDWINE_X11_SOURCES}
  ${BOXEDWINE_VULKAN_SOURCES}
  ${BOXEDWINE_SOFTFLOAT_SOURCES}
  ${BOXEDWINE_MINIZIP_SOURCES}
  "${CMAKE_CURRENT_SOURCE_DIR}/BoxedwineIOSPlatform.mm"
)

target_include_directories(boxedwine_runtime PUBLIC
  "${BOXEDWINE_SOURCE_DIR}/include"
  "${BOXEDWINE_SOURCE_DIR}/lib/sdl2/include"
  "${BOXEDWINE_SOURCE_DIR}/lib/simde"
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib"
  "${BOXEDWINE_SOURCE_DIR}/lib/zlib/contrib/minizip"
  "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/source"
  "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/source/8086-SSE"
  "${BOXEDWINE_SOURCE_DIR}/lib/softfloat/source/include"
)

target_compile_definitions(boxedwine_runtime PUBLIC
  BOXEDWINE_64
  BOXEDWINE_DISABLE_UI
  BOXEDWINE_EMBEDDED
  BOXEDWINE_POSIX
  BOXEDWINE_ZLIB
  SDL2=1
  SDL_MAIN_HANDLED
  SIMDE_NO_NEON
  SIMDE_SSE2_NO_NATIVE
  SIMDE_SSE2_NO_NEON
)

target_compile_options(boxedwine_runtime PRIVATE
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-delete-incomplete>
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-deprecated-declarations>
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-invalid-offsetof>
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-unknown-pragmas>
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-unused-function>
  $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:-Wno-unused-variable>
)

target_link_libraries(boxedwine_runtime PUBLIC
  SDL2-static
  "-lz"
)

set_target_properties(boxedwine_runtime PROPERTIES
  CXX_STANDARD 20
  CXX_STANDARD_REQUIRED YES
  XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
)
