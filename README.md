# SporeBridge for iOS

SporeBridge is an experimental, unofficial compatibility project intended to
test whether a legally purchased Windows copy of *Spore* can be run locally on
an iPhone or iPad.

This repository contains **no Spore game files, Electronic Arts code, artwork,
music or branding**. The user must supply their own installation. Imported
files remain on the device and are not uploaded to a server.

## Current milestone

Version 0.3.1 attaches the first interpreter-only Boxedwine bootstrap to the
import and validation shell:

- Presents a native iOS folder picker.
- Recognises base-game and Galactic Adventures executable layouts.
- Checks for `SporeApp.exe` and package data without relying on filename case.
- Copies a validated installation into the app's Documents directory.
- Generates a local import manifest.
- Reports the exact iPad/iPhone hardware identifier and iOS version.
- Verifies the non-executable virtual-memory operations required by the first
  Boxedwine interpreter build.
- Records the Metal graphics device and saves a JSON diagnostic report in the
  app's Documents directory.
- Builds the pinned Boxedwine core as an arm64 iOS static library, with no JIT
  or executable-memory entitlement.
- Bundles a project-authored 32-bit x86 Linux test programme containing no
  game or Wine files.
- Runs that programme headlessly through Boxedwine and verifies that its
  emulated file syscalls write a marker into the app's diagnostics folder.
- Flushes `boxedwine-bootstrap.log` after every embedded log write so a
  physical-device failure does not leave a misleading empty file.
- Saves `boxedwine-bootstrap-result.json` with the phase, exit code and marker
  result; an interrupted run remains recorded as `running`.

The longer runtime milestone uses
[Boxedwine](https://github.com/danoon2/Boxedwine), an open-source C++/SDL
runtime for 32-bit Windows applications. Boxedwine is a better initial fit than
a full Windows virtual machine because it already combines Wine with x86 CPU
and Linux-kernel emulation.

The selected upstream revision is pinned in `upstream.env`. Running
`bash scripts/prepare-boxedwine.sh DESTINATION` reconstructs that exact source and
verifies the SDL/iOS prerequisites that are already present upstream.
The concrete first-port configuration and device-test sequence are recorded in
`runtime/PORTING_NOTES.md`.

## Importing game files

1. Install and launch the unsigned IPA.
2. In Files, extract your purchased Spore installation if it is currently a
   ZIP archive.
3. In SporeBridge, choose the top-level installation folder.
4. The selected folder should contain:
   - `SporeBin/SporeApp.exe`, or
   - `SporebinEP1/SporeApp.exe` for Galactic Adventures.
5. It must also contain a data folder with at least one `.package` file.

Version 0.3.1 deliberately imports folders rather than extracting ZIP archives
inside the app. This keeps the first proof of concept small and auditable.

## Building the validator tests

On a normal C++17 development system:

```sh
g++ -std=c++17 -Wall -Wextra -Werror -pedantic \
  src/spore_install_validator.cpp \
  tests/spore_install_validator_tests.cpp \
  -Isrc -o spore_install_validator_tests
./spore_install_validator_tests
```

## Building the unsigned IPA

The included GitHub Actions workflow uses a macOS runner and Xcode to produce
an unsigned arm64 IPA. An Ubuntu job first assembles the minimal 32-bit x86
guest and packages its two-entry root ZIP. The macOS job reconstructs the
pinned Boxedwine source, applies the public iOS embedding patch, and links the
interpreter into SporeBridge.

## Status and limitations

The bootstrap has been compiled and run successfully on a Linux host using the
same non-JIT source selection. Passing it on a physical iPad will prove the
arm64 iOS interpreter, ELF loader and basic emulated syscalls, but still will
not prove Wine compatibility or playable speed. The next stage after that is a
redistributable Wine root, followed by process initialisation of the user's
locally supplied `SporeApp.exe`.

This is an independent preservation and compatibility experiment. It is not
affiliated with, authorised by or endorsed by Electronic Arts or Maxis.
