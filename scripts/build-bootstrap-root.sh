#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 OUTPUT_ZIP" >&2
  exit 2
fi

for command_name in as ld readelf zip; do
  if ! command -v "$command_name" >/dev/null; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
done

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$1"
if [[ "$output" != /* ]]; then
  output="$PWD/$output"
fi
mkdir -p "$(dirname "$output")"

work_directory="$(mktemp -d)"
trap 'rm -rf "$work_directory"' EXIT

as --32 \
  "$project_root/runtime/bootstrap/hello-i386.S" \
  -o "$work_directory/hello.o"
ld -m elf_i386 \
  --build-id=none \
  -nostdlib \
  -static \
  -e _start \
  "$work_directory/hello.o" \
  -o "$work_directory/hello"

readelf -h "$work_directory/hello" | grep -Fq "Class:                             ELF32"
readelf -h "$work_directory/hello" | grep -Fq "Machine:                           Intel 80386"

mkdir -p "$work_directory/root/bin" "$work_directory/root/tmp"
install -m 0755 "$work_directory/hello" "$work_directory/root/bin/hello"
(
  cd "$work_directory/root"
  zip -X -0 -q "$output" bin/hello tmp/
)

test -s "$output"
echo "Created minimal Boxedwine bootstrap root: $output"
