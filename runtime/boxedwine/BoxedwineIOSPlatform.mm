#import <Foundation/Foundation.h>

#include <cstring>
#include <string>

#include "pixelformat.h"

extern "C" {
int SDL_AppleTVRemoteOpenedAsJoystick = 0;
}

extern "C" void MacPlatormSetThreadPriority(void) {
}

extern "C" void MacPlatformOpenFileLocation(const char* location) {
  (void)location;
}

extern "C" const char* MacPlatformGetResourcePath(const char* name) {
  static thread_local std::string resourcePath;
  resourcePath.clear();

  if (name == nullptr) {
    return nullptr;
  }

  NSString* resourceName = [NSString stringWithUTF8String:name];
  NSString* path = [NSBundle.mainBundle pathForResource:resourceName
                                                 ofType:nil];
  if (path == nil) {
    return nullptr;
  }

  resourcePath = path.fileSystemRepresentation;
  return resourcePath.c_str();
}

int getPixelFormats(PixelFormat* formats, int maximumFormats) {
  if (formats == nullptr || maximumFormats < 2) {
    return 0;
  }

  std::memset(formats, 0, sizeof(PixelFormat) * 2);
  PixelFormat& format = formats[1];
  format.nSize = sizeof(PixelFormat);
  format.nVersion = 1;
  format.dwFlags =
      K_PFD_SUPPORT_OPENGL | K_PFD_DRAW_TO_WINDOW | K_PFD_DOUBLEBUFFER;
  format.iPixelType = K_PFD_TYPE_RGBA;
  format.cColorBits = 32;
  format.cRedBits = 8;
  format.cRedShift = 16;
  format.cGreenBits = 8;
  format.cGreenShift = 8;
  format.cBlueBits = 8;
  format.cBlueShift = 0;
  format.cAlphaBits = 8;
  format.cAlphaShift = 24;
  format.cDepthBits = 24;
  format.cStencilBits = 8;
  format.iLayerType = K_PFD_MAIN_PLANE;
  return 2;
}
