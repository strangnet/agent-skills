#!/usr/bin/env bash
# Empty Go module (stdlib only, builds offline).
set -euo pipefail
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p cart
printf '// Package cart computes shopping cart totals.\npackage cart\n' > cart/doc.go
