#!/usr/bin/env bash
# Checks that every plugin manifest declares the same version.
#
# .claude-plugin/plugin.json is the source of truth (Claude Code and Copilot
# read it). The Codex manifest in .codex-plugin/plugin.json and the
# marketplace entries for Claude Code and Codex must match it, because clients
# compare versions to decide whether an installed copy needs updating.
#
#   scripts/validate-versions.sh   exit 1 if any manifest's version differs (for CI)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
source_manifest=.claude-plugin/plugin.json
plugin_manifests=(
  .codex-plugin/plugin.json
)
marketplaces=(
  .claude-plugin/marketplace.json
  .agents/plugins/marketplace.json
)

expected=$(jq -r '.version // empty' "$root/$source_manifest")
if [ -z "$expected" ]; then
  echo "$source_manifest is missing a version field"
  exit 1
fi
if ! [[ $expected =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "$source_manifest has version $expected; expected MAJOR.MINOR.PATCH"
  exit 1
fi

name=$(jq -r '.name' "$root/$source_manifest")
status=0
for manifest in "${plugin_manifests[@]}"; do
  version=$(jq -r '.version // "<missing>"' "$root/$manifest")
  if [ "$version" != "$expected" ]; then
    echo "$manifest has version $version; expected $expected (from $source_manifest)"
    status=1
  fi
done
for manifest in "${marketplaces[@]}"; do
  version=$(jq -r --arg name "$name" \
    '.plugins[] | select(.name == $name) | .version // "<missing>"' \
    "$root/$manifest")
  if [ -z "$version" ]; then
    echo "$manifest has no entry for plugin $name"
    status=1
  elif [ "$version" != "$expected" ]; then
    echo "$manifest has version $version; expected $expected (from $source_manifest)"
    status=1
  fi
done

[ "$status" -eq 0 ] && echo "All plugin manifests use version $expected."
exit "$status"
