#!/usr/bin/env bash
# Empty Rust library crate, no dependencies (builds offline).
set -euo pipefail
cat > Cargo.toml <<'TOML'
[package]
name = "shop"
version = "0.1.0"
edition = "2021"
TOML
mkdir -p src
printf '//! Shopping cart.\n' > src/lib.rs
