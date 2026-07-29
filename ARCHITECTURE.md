# Architecture and feasibility gates

## Product boundary

The distributed IPA contains only project-owned code and redistributable
open-source dependencies. It never bundles the Spore executable, packages,
graphics, audio, registry data or installer.

Game files are selected by the user through the system Files picker and copied
locally into the app container. No server is involved.

## Runtime decision

The primary runtime candidate is Boxedwine:

- It runs 32-bit Windows programmes.
- It is implemented in C++ and uses SDL.
- It combines Wine with x86 CPU and Linux-kernel emulation.
- It has ARM64 and macOS support, giving the iOS port a nearer starting point
  than desktop-only Wine front-ends.
- Its GPL-2.0 licence is compatible with an open-source integration project,
  provided the combined source remains available under the required terms.

A full UTM/QEMU Windows virtual machine remains a fallback diagnostic route,
not the product architecture. On iPhone it adds a guest operating system,
greater storage requirements and an extra graphics boundary before Direct3D 9
can reach Metal.

## Milestones

### Gate 1: Installation import

Status: implemented in source.

Success means:

- iOS grants access to a selected folder.
- The app locates `SporeApp.exe`.
- At least one game package is present.
- The installation can be copied into the sandbox.

### Gate 2: Runtime boot

Status: upstream selected and pinned; iOS port not yet implemented.

Success means:

- Boxedwine compiles as arm64 for iOS.
- A redistributable Wine environment starts.
- The imported executable reaches process initialisation.
- Logs are written into the Documents directory.

The first target uses Boxedwine's normal interpreter, SDL's iOS backend and
the OpenGL-to-ES path. It does not enable JIT or request executable memory.
See `runtime/PORTING_NOTES.md` for the source seams and proof sequence.

### Gate 3: Graphics

Success means:

- Spore creates a Direct3D 9 device.
- The first rendered frame reaches an iOS surface.
- The app does not depend on private iOS APIs.

The first implementation may use a slower software path. Hardware translation
can be considered only after correctness is demonstrated.

### Gate 4: Interaction and playability

Success means:

- Mouse movement, primary/secondary click, drag and wheel inputs map to touch.
- Keyboard entry and controller input are available.
- Audio starts.
- Cell-stage gameplay can be entered and saved.

### Gate 5: Distribution review

Before public distribution:

- Obtain specialist intellectual-property advice.
- Review the exact Spore licence used by each supported store edition.
- Avoid Electronic Arts trademarks and artwork in the app name, icon and store
  listing unless permission is obtained.
- Publish all source and notices required by included open-source licences.

## File-layout detection

The validator intentionally uses a minimal, edition-tolerant rule:

- A case-insensitive `SporeApp.exe` must exist.
- A folder named `SporeBin` or `SporebinEP1` is preferred.
- A directory beginning with `Data` must contain at least one `.package` file.

This avoids locking the app to one installer or storefront before genuine
installations have been sampled.
