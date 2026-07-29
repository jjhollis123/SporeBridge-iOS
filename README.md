# SporeBridge for iOS

SporeBridge is an experimental, unofficial compatibility project intended to
test whether a legally purchased Windows copy of *Spore* can be run locally on
an iPhone or iPad.

This repository contains **no Spore game files, Electronic Arts code, artwork,
music or branding**. The user must supply their own installation. Imported
files remain on the device and are not uploaded to a server.

## Current milestone

Version 0.1 is the import and validation shell:

- Presents a native iOS folder picker.
- Recognises base-game and Galactic Adventures executable layouts.
- Checks for `SporeApp.exe` and package data without relying on filename case.
- Copies a validated installation into the app's Documents directory.
- Generates a local import manifest.
- Clearly reports that the Windows runtime is not attached yet.

The runtime milestone will integrate an iOS port of
[Boxedwine](https://github.com/danoon2/Boxedwine), an open-source C++/SDL
runtime for 32-bit Windows applications. Boxedwine is a better initial fit than
a full Windows virtual machine because it already combines Wine with x86 CPU
and Linux-kernel emulation.

The selected upstream revision is pinned in `upstream.env`. Running
`scripts/prepare-boxedwine.sh DESTINATION` reconstructs that exact source and
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

Version 0.1 deliberately imports folders rather than extracting ZIP archives
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
an unsigned arm64 IPA. The build contains only the native importer and
validator until the Boxedwine runtime milestone is completed.

## Status and limitations

Passing the import check proves only that iOS can receive and recognise a Spore
installation. It does not prove playable speed. The next decisive test is to
bring up Boxedwine on iOS, launch the supplied `SporeApp.exe`, and capture the
first graphics and diagnostic output.

This is an independent preservation and compatibility experiment. It is not
affiliated with, authorised by or endorsed by Electronic Arts or Maxis.
