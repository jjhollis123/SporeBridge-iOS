# Third-party notices

SporeBridge 0.3.1 builds the following components into its unsigned test IPA.
The build uses the exact Boxedwine revision recorded in `upstream.env` and
applies the source-level changes in `patches/boxedwine-ios-embedded.patch`.

## Boxedwine

- Project: <https://github.com/danoon2/Boxedwine>
- Licence: GNU General Public License, version 2 or later
- Source revision: `1f4ab58ada43ccb27aed41a35060d214671ddf16`

The complete corresponding integration source, upstream pin, build workflow
and patch are published in this repository. Boxedwine's full licence text is
also copied into the application bundle at build time.

## Simple DirectMedia Layer (SDL) 2.0.12

- Project: <https://www.libsdl.org/>
- Licence: zlib licence

SDL's copyright and licence notice is retained in its source checkout and
copied into the application bundle.

## Berkeley SoftFloat Release 3e

- Author: John R. Hauser
- Copyright: The Regents of the University of California
- Licence: 3-clause BSD licence

SoftFloat's complete notice is retained in its source checkout and copied into
the application bundle.

## zlib and MiniZip

- Project: <https://zlib.net/>
- Licence: zlib licence

The iOS target links the platform zlib library and compiles the MiniZip source
carried by the pinned Boxedwine checkout. Their notices remain with the
corresponding source.

No Electronic Arts or Maxis executable, package, artwork, audio or other game
asset is included in the application or its build inputs.
