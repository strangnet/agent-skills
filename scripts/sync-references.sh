#!/usr/bin/env bash
# Vendors shared reference files into each skill, so every skill stays
# self-contained when installed or copied on its own.
#
# A skill opts in by having a references/languages/ directory.
#
#   scripts/sync-references.sh          copy references/languages/*.md into every opted-in skill
#   scripts/sync-references.sh --check  exit 1 if any skill's copy has drifted (for CI)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
src="$root/references/languages"
mode=${1:-sync}
status=0

for dest in "$root"/skills/*/*/references/languages; do
  [ -d "$dest" ] || continue
  rel=${dest#"$root"/}
  if [ "$mode" = "--check" ]; then
    if ! diff -r -q "$src" "$dest" >/dev/null; then
      echo "out of sync: $rel (run scripts/sync-references.sh)"
      status=1
    fi
  else
    # Remove copies of languages that no longer exist at the source.
    for f in "$dest"/*.md; do
      [ -e "$f" ] || continue
      [ -e "$src/$(basename "$f")" ] || rm "$f"
    done
    cp "$src"/*.md "$dest"/
    echo "synced $rel"
  fi
done

exit "$status"
