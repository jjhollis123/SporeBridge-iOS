# Boxedwine iOS porting notes

Upstream is pinned by `upstream.env`. These notes describe the smallest
runtime experiment; they are not a claim that Spore is playable yet.

## Initial target

Build Boxedwine as an arm64 iOS static library and invoke it inside the
SporeBridge process. Keep the first target intentionally conservative:

- `BOXEDWINE_64` for the 64-bit host.
- `BOXEDWINE_POSIX` for the Unix-like host layer.
- `SDL2=1` with SDL's UIKit/iPhoneOS backend.
- `BOXEDWINE_ZLIB` for packaged runtime data.
- `BOXEDWINE_DISABLE_UI` and `-novideo -nosound` for the first headless proof.
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
3. Run the first bootstrap with SDL events only and no SDL window. A
   UIKit-owned graphics surface is a later adaptation.
4. Redirect logs, Wine prefix data and saves to the app's Documents or
   Application Support directories.
5. Bundle a redistributable Boxedwine/Wine root filesystem separately from
   the user's Spore files, with its corresponding source and licence notices.
6. Launch the executable recorded by `sporebridge-import.json`, initially with
   networking disabled and a fixed virtual desktop size.
7. Map touch and controller input only after a first frame is produced.

## Runtime proof sequence

The first device test stops at the earliest failing boundary and retains an
immediately flushed log plus `boxedwine-bootstrap-result.json`:

1. Start Boxedwine and mount a two-entry bootstrap ZIP.
2. Interpret the project-authored static 32-bit x86 Linux ELF.
3. Verify that `open`, `write`, `close` and `exit` create the marker file.
4. Add a redistributable Wine root and run a tiny Windows test executable.
5. Run a simple Direct3D 9 test and capture the first frame.
6. Mount `Documents/ImportedSpore` as the game source.
7. Start the detected `SporeApp.exe`.
8. Record process startup, DLL, graphics and audio failures.

Only step 7 requires the user's locally supplied Spore installation. None of
those files should be committed, uploaded by the app or included in an IPA.

## Go/no-go gate

Continue towards a playable build only if a physical device can reach Spore's
process initialisation and create a graphics surface without private APIs. If
the interpreter is correct but too slow, performance work becomes a separate
decision involving App Store policy, signing entitlements and alternative
translation strategies.
