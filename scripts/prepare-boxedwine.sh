#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 DESTINATION" >&2
  exit 2
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$project_root/upstream.env"

destination="$1"
if [[ -e "$destination" ]]; then
  echo "Destination already exists: $destination" >&2
  exit 1
fi

git clone --no-checkout --filter=blob:none \
  "$BOXEDWINE_REPOSITORY" "$destination"
git -C "$destination" checkout --detach "$BOXEDWINE_COMMIT"

actual_commit="$(git -C "$destination" rev-parse HEAD)"
if [[ "$actual_commit" != "$BOXEDWINE_COMMIT" ]]; then
  echo "Boxedwine commit mismatch" >&2
  exit 1
fi

test -f "$destination/LICENSE"
test -f "$destination/platform/sdl/knativescreenSDL.cpp"
test -f "$destination/lib/sdl2/include/SDL_config_iphoneos.h"

echo "Prepared Boxedwine $actual_commit"

