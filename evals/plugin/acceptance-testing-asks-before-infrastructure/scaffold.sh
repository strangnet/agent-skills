#!/usr/bin/env bash
# Go module for a shop with no acceptance-test infrastructure yet.
set -euo pipefail
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p cmd/shop
printf 'package main\n\nfunc main() {}\n' > cmd/shop/main.go
