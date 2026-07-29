# Boxedwine iOS porting notes

Upstream is pinned by `upstream.env`. These notes describe the smallest
runtime experiment; they are not a claim that Spore is playable yet.

## Initial target

Build Boxedwine as an arm64 iOS static library and invoke it inside the
SporeBridge process. Keep the first target intentionally conservative:

- `BOXEDWINE_64` for the 64-bit host.
- `BOXEDWINE_ES` for Boxedwine's OpenGL-to-OpenGL-ES translation path.
- `BOXEDWINE_POSIX` for the Unix-like host layer.
- `SDL2=1` with SDL's UIKit/iPhoneOS backend.
- `BOXEDWINE_ZLIB` for packaged runtime data.
- No `BOXEDWINE_JIT`, `BOXEDWINE_JIT_ARMV8` or executable-memory entitlement
  in the first build.
- Start single-threaded, then enable `BOXEDWINE_MULTI_THREADED` only after the
  process and graphics paths are stable.

This is a correctness-first configuration. Interpreter performance may be
insufficient for gameplay, but it gives a clean answer about whether the
Windows process and Direct3D 9 stack can initialise.

## Reusable upstream components

- `source/emulation/cpu/normal`: non-JIT x86 CPU implementation.
- `source/opengl/es`: OpenGL-to-ES translation.
- `platform/sdl`: screen, input and audio abstractions.
- `lib/sdl2/Xcode-iOS`: upstream SDL iOS project material.
- `lib/sdl2/include/SDL_config_iphoneos.h`: iOS SDL configuration.
- `platform/linux/platform.cpp`: most POSIX filesystem, timing, socket and
  virtual-memory behaviour is a useful starting point.

## Required iOS adaptations

1. Add `platform/ios/platform.mm` rather than compiling the macOS bridge.
   Resource lookup must use `NSBundle`; opening files must use UIKit APIs or
   be disabled. App-owned paths must stay inside the sandbox.
2. Audit the POSIX virtual-memory functions on a physical iOS device. The
   interpreter needs readable and writable guest memory, but the first target
   must not request executable mappings.
3. Provide a UIKit-owned SDL surface. Boxedwine must not create a second app
   event loop or desktop window.
4. Redirect logs, Wine prefix data and saves to the app's Documents or
   Application Support directories.
5. Bundle a redistributable Boxedwine/Wine root filesystem separately from
   the user's Spore files, with its corresponding source and licence notices.
6. Launch the executable recorded by `sporebridge-import.json`, initially with
   networking disabled and a fixed virtual desktop size.
7. Map touch and controller input only after a first frame is produced.

## Runtime proof sequence

The first device test should stop at the earliest failing boundary and retain
logs:

1. Start Boxedwine and mount its root filesystem.
2. Run a tiny redistributable 32-bit Windows test executable.
3. Run a simple Direct3D 9 test and capture the first frame.
4. Mount `Documents/ImportedSpore` read-only as the game source.
5. Start the detected `SporeApp.exe`.
6. Record process startup, DLL, graphics and audio failures.

Only step 5 requires the user's locally supplied Spore installation. None of
those files should be committed, uploaded by the app or included in an IPA.

## Go/no-go gate

Continue towards a playable build only if a physical device can reach Spore's
process initialisation and create a graphics surface without private APIs. If
the interpreter is correct but too slow, performance work becomes a separate
decision involving App Store policy, signing entitlements and alternative
translation strategies.
